defmodule Pyro.HEEx do
  @moduledoc """
  Tooling for transforming Pyro.HEEx.AST.

  The primary purpose is to enable Pyro to transform HTML attributes, so interpolated Elixir is not parsed.

  It's basically an HTML parser that can ignore and preserve HEEx/EEx interpolation.
  """

  alias __MODULE__.AST
  alias __MODULE__.AST.{Element, Component, Attribute}

  defp attribute_matches?(attr_name, pattern) when is_binary(pattern) do
    attr_name == pattern
  end

  defp attribute_matches?(attr_name, %Regex{} = pattern) do
    Regex.match?(pattern, attr_name)
  end

  defp normalize_attribute_patterns(patterns) do
    Enum.map(List.wrap(patterns), fn
      pattern when is_binary(pattern) ->
        String.downcase(pattern)

      pattern when is_struct(pattern, Regex) ->
        %{pattern | opts: Enum.uniq([:caseless | pattern.opts])}

      _ ->
        raise ArgumentError, "Pattern must be either a string or regex."
    end)
  end

  defguard is_struct_with_attributes(type)
           when is_struct(type, Component) or is_struct(type, Element)

  @doc """
  Tallies attribute values in the AST for a given attribute pattern or list of patterns.

  Accepts:
  - A string for exact attribute name matching
  - A regex for pattern matching attribute names
  - A list containing any combination of strings and regexes

  Boolean attributes are counted as having a true value.
  HEEx expressions in attribute values are converted to strings.

  Returns a map where keys are attribute names found, and values are maps
  containing each unique value as a key with its occurrence count as the value.
  When multiple patterns match the same attribute, their counts are combined.

  ## Examples

  """
  @spec tally_attributes(
          AST.t(),
          String.t() | Regex.t() | [String.t() | Regex.t()]
        ) :: %{
          String.t() => %{any() => non_neg_integer()}
        }
  def tally_attributes(%AST{nodes: nodes}, patterns) do
    tally_attributes_for_nodes(nodes, %{}, normalize_attribute_patterns(patterns))
  end

  defp tally_attributes_for_nodes([], tally, _patterns) do
    tally
  end

  defp tally_attributes_for_nodes([node | rest], tally, patterns) do
    tally = tally_attributes_for_node(node, tally, patterns)
    tally_attributes_for_nodes(rest, tally, patterns)
  end

  defp tally_attributes_for_node(node, tally, patterns) when is_struct_with_attributes(node) do
    tally =
      Enum.reduce(node.attributes, tally, fn attribute, tally ->
        Enum.reduce(patterns, tally, &tally_match(&1, &2, attribute))
      end)

    tally_attributes_for_nodes(node.children, tally, patterns)
  end

  defp tally_attributes_for_node(_node, tally, _patterns), do: tally

  defp tally_match(pattern, tally, attribute) do
    if attribute_matches?(attribute.name, pattern) do
      tally
      |> Map.update(attribute.name, %{attribute.value => 1}, fn values ->
        Map.update(values, attribute.value, 1, &(&1 + 1))
      end)
    else
      tally
    end
  end

  @doc """
  Removes matching attributes from the AST and returns them with their paths.

  Accepts:
  - A string for exact attribute name matching
  - A regex for pattern matching attribute names
  - A list containing any combination of strings and regexes

  Takes the same arguments as `tally_attributes/2` but instead of counting occurrences,
  it removes matching attributes from the AST and returns a tuple containing the
  modified AST and a list of removed attributes with their paths.

  Each removed attribute is represented as `{path, attribute}` where:
  - `path` is a list of integers representing the path to the element in the AST
  - `attribute_name` is the string name of the attribute
  - `attribute_value` is the attribute value

  ## Examples

      iex> ast = parse!(~S(<div pyro-component="button" class="btn"></div>))
      iex> ast = pop_attributes(ast, "pyro-component")
      iex> [%Element{attributes: [%Attribute{name: "class"}], tag: "div"}] = ast.nodes
      iex> [{[0], %Attribute{name: "pyro-component"}}] = ast.context.popped_attributes
  """
  @spec pop_attributes(
          AST.t(),
          String.t() | Regex.t() | [String.t() | Regex.t()]
        ) :: AST.t()
  def pop_attributes(%AST{} = ast, patterns) do
    patterns = normalize_attribute_patterns(patterns)
    {nodes, popped} = pop_attributes_from_nodes(ast.nodes, [], [], patterns, [])

    ast
    |> Map.put(:nodes, nodes)
    |> Map.update!(:context, fn context ->
      Map.put(context, :popped_attributes, Enum.reverse(popped))
    end)
  end

  defp pop_attributes_from_nodes([], acc, popped, _patterns, _path) do
    {Enum.reverse(acc), popped}
  end

  defp pop_attributes_from_nodes([node | rest], acc, popped, patterns, path) do
    {node, popped} = pop_attributes_from_node(node, popped, patterns, path ++ [length(acc)])
    pop_attributes_from_nodes(rest, [node | acc], popped, patterns, path)
  end

  defp pop_attributes_from_node(node, popped, patterns, path)
       when is_struct_with_attributes(node) do
    {attributes, popped} =
      Enum.reduce(node.attributes, {[], popped}, fn attribute, {attributes, popped} ->
        if Enum.any?(patterns, &attribute_matches?(attribute.name, &1)) do
          {attributes, [{path, attribute} | popped]}
        else
          {[attribute | attributes], popped}
        end
      end)

    {children, popped} =
      pop_attributes_from_nodes(node.children, [], popped, patterns, path)

    {%{node | attributes: Enum.reverse(attributes), children: children}, popped}
  end

  defp pop_attributes_from_node(node, popped, _patterns, _path) do
    {node, popped}
  end

  @doc """
  Adds attributes to an element at the specified path in the AST.

  The path is a list of integers representing the location of the target element
  in the AST tree.

  > #### Note: {: .info}
  >
  > Attributes are appended.

  ## Examples

      iex> ast = parse!(~S(<input />))
      iex> {:ok, ast} = add_attributes(ast, [0], %Attribute{name: "disabled"})
      iex> ~S(<input disabled />) = encode(ast)
      iex> {:ok, ast} = add_attributes(ast, [0], [%Attribute{name: "type", value: "button"}, %Attribute{name: "label", type: :expression, value: "@label"}])
      iex> ~S(<input disabled type="button" label={@label} />) = encode(ast)

  """
  @spec add_attributes(
          AST.t(),
          [non_neg_integer()],
          Attribute.t() | [Attribute.t()]
        ) :: {:ok, AST.t()} | {:error, String.t()}
  def add_attributes(ast, path, attributes) do
    attributes = List.wrap(attributes)
    {:ok, Map.update!(ast, :nodes, &add_attributes_at_path(&1, path, attributes))}
  rescue
    e -> {:error, Exception.message(e)}
  end

  @spec add_attributes!(
          AST.t(),
          [non_neg_integer()],
          Attribute.t() | [Attribute.t()]
        ) :: AST.t()
  def add_attributes!(ast, path, attributes) do
    attributes = List.wrap(attributes)
    Map.update!(ast, :nodes, &add_attributes_at_path(&1, path, attributes))
  end

  defp add_attributes_at_path(_ast, [], _attributes) do
    raise ArgumentError, "Cannot add attribute at empty path - path must target an element"
  end

  defp add_attributes_at_path(ast, [index], attributes) when is_list(ast) do
    List.update_at(ast, index, fn
      node when is_struct_with_attributes(node) ->
        attributes = AST.parse_attributes(attributes)
        %{node | attributes: node.attributes ++ attributes}

      other ->
        raise ArgumentError, "Cannot add attribute to non-element node: #{inspect(other)}"
    end)
  end

  defp add_attributes_at_path(ast, [index | rest_path], attributes) when is_list(ast) do
    List.update_at(ast, index, fn
      node when is_struct_with_attributes(node) ->
        %{node | children: add_attributes_at_path(node.children, rest_path, attributes)}

      other ->
        raise ArgumentError, "Cannot navigate through non-element node: #{inspect(other)}"
    end)
  end
end
