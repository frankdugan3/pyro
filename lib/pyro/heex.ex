defmodule Pyro.HEEx do
  @moduledoc """
  A simple parser for HEEx template strings.

  The purpose is to enable Pyro to transform HTML attributes, so interpolated Elixir is not parsed. It's basically an HTML parser that can ignore and preserve HEEx/EEx interpolation.


  > #### Note: {: .warning}
  >
  > It is not a 100% pure round trip to parse/encode. The parser and encoder will:
  >
  > - Downcase tag and attribute names
  > - Normalize boolean attributes
  > - Trim whitespace inside tags and between attributes
  >
  > The reason for this is to simplify the AST and also provide a better result when formatting transformed AST.
  """

  import __MODULE__.AST

  alias __MODULE__.AST

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

  @doc """
  Parses a HEEx template string into an AST.

  ## Examples

      iex> parse("<div>Hello</div>")
      {:ok, %AST{nodes: [{:element, "div", [], [{:text, "Hello"}]}]}}

      iex> parse("<p class='bold'>{@name}</p>")
      {:ok, %AST{nodes: [{:element, "p", [{"class", "bold"}], [{:heex_expr, "@name"}]}]}}
  """
  @spec parse(String.t()) :: {:ok, AST.t()} | {:error, String.t()}
  def parse(template) when is_binary(template) do
    ast = parse_template!(template)
    {:ok, ast}
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc """
  Parses a HEEx template string into an AST.

  ## Examples

      iex> parse!("<div>Hello</div>")
      %AST{nodes: [{:element, "div", [], [{:text, "Hello"}]}]}

      iex> parse!("<p class='bold'>{@name}</p>")
      %AST{nodes: [{:element, "p", [{"class", "bold"}], [{:heex_expr, "@name"}]}]}
  """
  @spec parse!(String.t()) :: AST.t()
  def parse!(template) when is_binary(template), do: parse_template!(template)

  @doc """
  Encodes an AST back into a HEEx template string.

  ## Examples

      iex> ast = %AST{nodes: [{:element, "div", [], [{:text, "Hello"}]}]}
      iex> encode(ast)
      "<div>Hello</div>"
  """
  @spec encode(AST.t()) :: String.t()
  def encode(%AST{nodes: nodes}), do: encode_nodes(nodes)

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

      iex> ast = %AST{nodes: [{:element, "div", [{"pyro-component", "button"}, {"disabled", true}], []}]}
      iex> tally_attributes(ast, "pyro-component")
      %{"pyro-component" => %{"button" => 1}}

      iex> ast = %AST{nodes: [
      ...>   {:element, "div", [{"pyro-test", "value1"}], []},
      ...>   {:element, "span", [{"pyro-test", "value2"}, {"pyro-other", "value3"}], []}
      ...> ]}
      iex> tally_attributes(ast, ~r/^pyro-/)
      %{"pyro-test" => %{"value1" => 1, "value2" => 1}, "pyro-other" => %{"value3" => 1}}

      iex> ast = %AST{nodes: [{:element, "input", [{"required", true}, {"disabled", true}], []}]}
      iex> tally_attributes(ast, ["required", "disabled"])
      %{"required" => %{true => 1}, "disabled" => %{true => 1}}
  """
  @spec tally_attributes(
          AST.t(),
          String.t() | Regex.t() | [String.t() | Regex.t()]
        ) :: %{
          String.t() => %{any() => non_neg_integer()}
        }
  def tally_attributes(%AST{nodes: nodes}, patterns) do
    Enum.reduce(normalize_attribute_patterns(patterns), %{}, fn pattern, acc ->
      nodes
      |> traverse_for_tallying(%{}, pattern)
      |> Map.merge(acc, fn _key, v1, v2 ->
        Map.merge(v1, v2, fn _inner_key, count1, count2 -> count1 + count2 end)
      end)
    end)
  end

  defp traverse_for_tallying([], acc, _pattern), do: acc

  defp traverse_for_tallying([node | rest], acc, pattern) do
    updated_acc = traverse_node_for_tallying(node, acc, pattern)
    traverse_for_tallying(rest, updated_acc, pattern)
  end

  defp traverse_node_for_tallying({:element, _tag_name, attributes, children}, acc, pattern) do
    attr_acc = tally_matching_attributes(attributes, acc, pattern)

    traverse_for_tallying(children, attr_acc, pattern)
  end

  defp traverse_node_for_tallying(_other_node, acc, _pattern) do
    acc
  end

  defp tally_matching_attributes([], acc, _pattern), do: acc

  defp tally_matching_attributes([{attr_name, attr_value} | rest], acc, pattern) do
    updated_acc =
      if attribute_matches?(attr_name, pattern) do
        increment_tally(acc, attr_name, attr_value)
      else
        acc
      end

    tally_matching_attributes(rest, updated_acc, pattern)
  end

  defp increment_tally(acc, attr_name, value) do
    Map.update(acc, attr_name, %{value => 1}, fn attr_map ->
      Map.update(attr_map, value, 1, &(&1 + 1))
    end)
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

  Each removed attribute is represented as `{path, attribute_name, attribute_value}` where:
  - `path` is a list of integers representing the path to the element in the AST
  - `attribute_name` is the string name of the attribute
  - `attribute_value` is the attribute value

  ## Examples

      iex> ast = %AST{nodes: [{:element, "div", [{"pyro-component", "button"}, {"class", "btn"}], []}]}
      iex> pop_attributes(ast, "pyro-component")
      %AST{nodes: [{:element, "div", [{"class", "btn"}], []}], context: %{popped_attributes: [{[0], "pyro-component", "button"}]}}

      iex> ast = %AST{nodes: [
      ...>   {:element, "div", [{"pyro-test", "value1"}], [
      ...>     {:element, "span", [{"pyro-test", "value2"}, {"other", "keep"}], []}
      ...>   ]}
      ...> ]}
      iex> pop_attributes(ast, ~r/^pyro-/)
      %AST{nodes: [{:element, "div", [], [{:element, "span", [{"other", "keep"}], []}]}], context: %{popped_attributes: [{[0], "pyro-test", "value1"}, {[0, 0], "pyro-test", "value2"}]}}

      iex> ast = %AST{nodes: [{:element, "div", [{"id", "main"}, {"class", "btn"}, {"disabled", true}], []}]}
      iex> pop_attributes(ast, ["id", "disabled"])
      %AST{nodes: [{:element, "div", [{"class", "btn"}], []}], context: %{popped_attributes: [{[0], "id", "main"}, {[0], "disabled", true}]}}

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

  defp pop_attributes_from_node({:element, tag, attributes, children}, popped, patterns, path) do
    {attributes, popped} =
      Enum.reduce(attributes, {[], popped}, fn {name, value}, {attributes, popped} ->
        if Enum.any?(patterns, &attribute_matches?(name, &1)) do
          {attributes, [{path, name, value} | popped]}
        else
          {[{name, value} | attributes], popped}
        end
      end)

    {children, popped} =
      pop_attributes_from_nodes(children, [], popped, patterns, path)

    {{:element, tag, Enum.reverse(attributes), children}, popped}
  end

  defp pop_attributes_from_node(node, popped, _patterns, _path) do
    {node, popped}
  end

  @doc """
  Adds an attribute to an element at the specified path in the AST.

  The path is a list of integers representing the location of the target element
  in the AST tree, following the same format as used by `pop_attributes/2`.


  > #### Note: {: .info}
  >
  > Attributes are prepended.

  ## Examples

      iex> ast = %AST{nodes: [{:element, "div", [{"class", "btn"}], []}]}
      iex> add_attribute(ast, [0], {"id", "my-div"})
      {:ok, %AST{nodes: [{:element, "div", [{"id", "my-div"}, {"class", "btn"}], []}]}}

      iex> ast = %AST{nodes: [{:element, "div", [], [{:element, "span", [], []}]}]}
      iex> add_attribute(ast, [0, 0], {"class", "highlight"})
      {:ok, %AST{nodes: [{:element, "div", [], [{:element, "span", [{"class", "highlight"}], []}]}]}}

  """
  @spec add_attribute(
          AST.t(),
          [non_neg_integer()],
          AST.attribute()
        ) :: {:ok, AST.t()} | {:error, String.t()}
  def add_attribute(ast, path, {name, value}) do
    name = String.downcase(name)
    {:ok, Map.update!(ast, :nodes, &add_attribute_at_path(&1, path, {name, value}))}
  rescue
    e -> {:error, Exception.message(e)}
  end

  @spec add_attribute!(
          AST.t(),
          [non_neg_integer()],
          AST.attribute()
        ) :: AST.t()
  def add_attribute!(ast, path, {name, value}) do
    name = String.downcase(name)
    Map.update!(ast, :nodes, &add_attribute_at_path(&1, path, {name, value}))
  end

  defp add_attribute_at_path(_ast, [], _attribute) do
    raise ArgumentError, "Cannot add attribute at empty path - path must target an element"
  end

  defp add_attribute_at_path(ast, [index], attribute) when is_list(ast) do
    List.update_at(ast, index, fn
      {:element, tag, attributes, children} ->
        {:element, tag, [attribute | attributes], children}

      other ->
        raise ArgumentError, "Cannot add attribute to non-element node: #{inspect(other)}"
    end)
  end

  defp add_attribute_at_path(ast, [index | rest_path], attribute) when is_list(ast) do
    List.update_at(ast, index, fn
      {:element, tag, attributes, children} ->
        {:element, tag, attributes, add_attribute_at_path(children, rest_path, attribute)}

      other ->
        raise ArgumentError, "Cannot navigate through non-element node: #{inspect(other)}"
    end)
  end
end
