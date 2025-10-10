defmodule Pyro.HEEx.AST do
  @moduledoc """
  Tooling to parse HEEx into AST, and from AST to HEEx.

  > #### Note: {: .warning}
  >
  > It is not a 100% pure round trip to parse/encode. The parser and encoder will:
  >
  > - Downcase tag and attribute names
  > - Normalize boolean attributes
  > - Trim whitespace inside tags and between attributes
  >
  > The reason for this is to simplify the AST for transformation, and to provide a better result when formatting transformed AST.
  """
  alias Phoenix.LiveView.HTMLEngine
  alias Phoenix.LiveView.Tokenizer
  alias Pyro.HEEx.AST
  alias Pyro.HEEx.AST.ParseError

  require Logger

  defmodule Text do
    @moduledoc """
    Represents plain text content in HEEx templates.

    Stores text content, surrounding whitespace, and source position.
    """
    # quokka:sort
    defstruct [:column, :content, :line, :post, :pre]

    @type t :: %__MODULE__{
            column: non_neg_integer() | nil,
            content: String.t(),
            line: non_neg_integer() | nil,
            post: String.t(),
            pre: String.t()
          }
  end

  defmodule HTMLComment do
    @moduledoc """
    Represents HTML comments (`<!-- ... -->`) in HEEx templates.

    Stores comment content, surrounding whitespace, and source position.
    """
    # quokka:sort
    defstruct [:column, :content, :line, :post, :pre]

    @type t :: %__MODULE__{
            column: non_neg_integer() | nil,
            content: String.t(),
            line: non_neg_integer() | nil,
            post: String.t(),
            pre: String.t()
          }
  end

  defmodule EExComment do
    @moduledoc """
    Represents EEx comments (`<%!-- ... --%>`) in HEEx templates.

    Stores comment content, surrounding whitespace, and source position.
    """
    # quokka:sort
    defstruct [:column, :content, :line, :post, :pre]

    @type t :: %__MODULE__{
            column: non_neg_integer() | nil,
            content: String.t(),
            line: non_neg_integer() | nil,
            post: String.t(),
            pre: String.t()
          }
  end

  defmodule Expression do
    @moduledoc """
    Represents HEEx expressions (`{...}`) for inline interpolation in HEEx templates.

    Stores expression code, surrounding whitespace, and source position.
    """
    # quokka:sort
    defstruct [:column, :expression, :line, :post, :pre]

    @type t :: %__MODULE__{
            column: non_neg_integer() | nil,
            expression: String.t(),
            line: non_neg_integer() | nil,
            post: String.t(),
            pre: String.t()
          }
  end

  defmodule EExExpression do
    @moduledoc """
    Represents EEx expressions (`<%= ... %>`) for HEEx template logic.

    Stores expression code, operator, surrounding whitespace, and source position.
    """
    # quokka:sort
    defstruct [:column, :expression, :line, :operator, :post, :pre]

    @type t :: %__MODULE__{
            column: non_neg_integer() | nil,
            expression: String.t(),
            line: non_neg_integer() | nil,
            operator: String.t(),
            post: String.t(),
            pre: String.t()
          }
  end

  defmodule Element do
    @moduledoc """
    Represents HTML elements in HEEx templates.

    Stores tag name, attributes, children, self-closing status, and source position.
    """
    # quokka:sort
    defstruct [
      :column,
      :line,
      :post,
      :pre,
      :tag,
      attributes: [],
      children: [],
      self_closing?: false
    ]

    @type t :: %__MODULE__{
            attributes: [AST.Attribute.t()],
            children: [AST.ast_node()],
            self_closing?: boolean(),
            column: non_neg_integer() | nil,
            line: non_neg_integer() | nil,
            post: String.t(),
            pre: String.t(),
            tag: String.t()
          }
  end

  defmodule Component do
    @moduledoc """
    Represents Phoenix components (`<.component_name>`) in HEEx templates.

    Stores component name, attributes, children, self-closing status, and source position.
    """
    # quokka:sort
    defstruct [
      :column,
      :line,
      :name,
      :post,
      :pre,
      attributes: [],
      children: [],
      self_closing?: false
    ]

    @type t :: %__MODULE__{
            attributes: [AST.Attribute.t()],
            children: [AST.ast_node()],
            self_closing?: boolean(),
            column: non_neg_integer() | nil,
            line: non_neg_integer() | nil,
            name: String.t(),
            post: String.t(),
            pre: String.t()
          }
  end

  defmodule Slot do
    @moduledoc """
    Represents component slots (`<:slot_name>`) in HEEx templates.

    Stores slot name, attributes, children, and source position.
    """
    # quokka:sort
    defstruct [
      :column,
      :line,
      :name,
      :post,
      :pre,
      attributes: [],
      children: []
    ]

    @type t :: %__MODULE__{
            attributes: [AST.Attribute.t()],
            children: [AST.ast_node()],
            column: non_neg_integer() | nil,
            line: non_neg_integer() | nil,
            name: String.t(),
            post: String.t(),
            pre: String.t()
          }
  end

  defmodule Attribute do
    @moduledoc """
    Represents element/component attributes in HEEx templates.

    Stores attribute name, value, type, delimiter, and source position.
    """
    # quokka:sort
    defstruct [:column, :line, :name, :value, delimiter: ?\", type: :string]
    @type attr_type :: :string | :root | :boolean | :expression
    @type t :: %__MODULE__{
            name: String.t(),
            value: String.t() | boolean(),
            type: attr_type(),
            delimiter: char() | nil,
            line: non_neg_integer() | nil,
            column: non_neg_integer() | nil
          }
  end

  # quokka:sort
  defstruct [:source, context: %{}, nodes: [], opts: []]

  @type t :: %__MODULE__{
          context: map(),
          nodes: [ast_node()],
          opts: opts(),
          source: String.t()
        }

  @type opts :: keyword()
  @type ast_node ::
          Text.t()
          | HTMLComment.t()
          | EExComment.t()
          | Expression.t()
          | EExExpression.t()
          | Element.t()
          | Component.t()
          | Slot.t()

  @doc """
  Encodes an AST back into a HEEx template string.
  """
  @spec encode(t()) :: String.t()
  def encode(ast), do: ast_to_string(ast.nodes)

  defp ast_to_string(nodes) when is_list(nodes), do: Enum.map_join(nodes, &node_to_string/1)
  defp ast_to_string(node), do: node_to_string(node)

  defp node_to_string(%Text{content: content, post: post, pre: pre}) do
    "#{pre}#{content}#{post}"
  end

  defp node_to_string(%HTMLComment{content: content, post: post, pre: pre}) do
    "#{pre}<!--#{content}-->#{post}"
  end

  defp node_to_string(%EExComment{content: content, post: post, pre: pre}) do
    "#{pre}<%!--#{content}--%>#{post}"
  end

  defp node_to_string(%Expression{expression: expr, post: post, pre: pre}) do
    "#{pre}{#{expr}}#{post}"
  end

  defp node_to_string(%EExExpression{expression: expr, operator: operator, post: post, pre: pre}) do
    "#{pre}<%#{operator} #{expr} %>#{post}"
  end

  defp node_to_string(%Element{
         attributes: attrs,
         children: children,
         post: post,
         pre: pre,
         self_closing?: self_closing?,
         tag: tag
       }) do
    attrs_str = attributes_to_string(attrs)

    if self_closing? do
      "#{pre}<#{tag}#{attrs_str} />#{post}"
    else
      children_str = ast_to_string(children)
      "#{pre}<#{tag}#{attrs_str}>#{children_str}</#{tag}>#{post}"
    end
  end

  defp node_to_string(%Component{
         attributes: attrs,
         children: children,
         name: name,
         post: post,
         pre: pre,
         self_closing?: self_closing?
       }) do
    attrs_str = attributes_to_string(attrs)
    component_tag = ".#{name}"

    if self_closing? do
      "#{pre}<#{component_tag}#{attrs_str} />#{post}"
    else
      children_str = ast_to_string(children)
      "#{pre}<#{component_tag}#{attrs_str}>#{children_str}</#{component_tag}>#{post}"
    end
  end

  defp node_to_string(%Slot{
         attributes: attrs,
         children: children,
         name: name,
         post: post,
         pre: pre
       }) do
    attrs_str = attributes_to_string(attrs)
    slot_tag = ":#{name}"
    children_str = ast_to_string(children)

    "#{pre}<#{slot_tag}#{attrs_str}>#{children_str}</#{slot_tag}>#{post}"
  end

  defp attributes_to_string([]), do: ""
  defp attributes_to_string(attrs), do: Enum.map_join(attrs, &attribute_to_string/1)

  defp attribute_to_string(%Attribute{type: :root, value: value}), do: " {#{value}}"
  defp attribute_to_string(%Attribute{name: name, type: :boolean, value: true}), do: " #{name}"
  defp attribute_to_string(%Attribute{name: _name, type: :boolean, value: false}), do: ""

  defp attribute_to_string(%Attribute{name: name, type: :expression, value: value}),
    do: " #{name}={#{value}}"

  defp attribute_to_string(%Attribute{delimiter: d, name: name, value: value}),
    do: " #{name}=#{<<d>>}#{value}#{<<d>>}"

  defp parse_opts(template, opts) do
    trailing =
      case Regex.run(~r/[^\s]([\s]*)$/s, template) do
        [_, whitespace] ->
          whitespace

        _ ->
          if String.trim(template) == "" do
            template
          else
            ""
          end
      end

    opts
    |> Keyword.put_new(:file, "nofile")
    |> Keyword.put_new(:indentation, 0)
    |> Keyword.put_new(:source_offset, 0)
    |> Keyword.put_new(:tag_handler, HTMLEngine)
    |> Keyword.put_new(:pretty_errors?, true)
    |> Keyword.put(:trailing_whitespace, trailing)
  end

  @doc """
  Parses HEEx template string into an AST.
  """
  @spec parse(String.t(), opts()) ::
          {:ok, t()}
          | {:error, message :: String.t(),
             metadata :: %{column: non_neg_integer(), line: non_neg_integer()}}
  def parse(template, opts \\ []) do
    opts = parse_opts(template, opts)

    template
    |> tokenize_eex(opts)
    |> finalize(template, opts)
    |> to_ast(template, opts)
  end

  @spec parse!(String.t(), opts()) :: t()
  def parse!(template, opts \\ []) do
    opts = parse_opts(template, opts)

    case parse(template, opts) do
      {:ok, %__MODULE__{} = ast} ->
        ast

      {:error, message, meta} ->
        raise ParseError,
          file: opts[:file],
          indentation: opts[:indentation],
          source_offset: opts[:source_offset],
          source: template,
          line: meta.line,
          column: meta.column,
          message: message,
          pretty?: opts[:pretty_errors?]
    end
  end

  defp tokenize_eex(template, opts) do
    case EEx.tokenize(template, opts) do
      {:ok, eex_nodes} ->
        {tokens, cont} =
          Enum.reduce(
            eex_nodes,
            {[], {:text, :enabled}},
            &tokenize(&1, &2, [{:source, template} | opts])
          )

        {:ok, tokens, cont}

      {:error, message, meta} ->
        {:error, message, meta}
    end
  rescue
    error in Tokenizer.ParseError ->
      {:error, error.description, %{column: error.column, line: error.line}}
  end

  defp finalize({:ok, tokens, cont}, template, opts) do
    {:ok, Tokenizer.finalize(tokens, opts[:file], cont, template)}
  rescue
    error in Tokenizer.ParseError ->
      {:error, error.description, %{column: error.column, line: error.line}}
  end

  defp finalize({:error, message, meta}, _template, _opts) do
    {:error, message, meta}
  end

  defguard is_tag(type) when type in [:slot, :remote_component, :local_component, :tag]
  defguard is_eex_expr(type) when type in [:start_expr, :expr, :end_expr, :middle_expr]

  defp tokenize({:text, text, meta}, {tokens, cont}, opts) do
    text = List.to_string(text)
    meta = [line: meta.line, column: meta.column]
    state = Tokenizer.init(opts[:indentation], opts[:file], opts[:source], opts[:tag_handler])
    Tokenizer.tokenize(text, meta, tokens, cont, state)
  end

  defp tokenize({:comment, text, meta}, {tokens, cont}, _opts) do
    {[{:eex_comment, List.to_string(text), meta} | tokens], cont}
  end

  defp tokenize({type, opt, expr, %{column: column, line: line}}, {tokens, cont}, _opts)
       when is_eex_expr(type) do
    meta = %{column: column, line: line, opt: opt}
    {[{:eex, type, expr |> List.to_string() |> String.trim(), meta} | tokens], cont}
  end

  defp tokenize(_node, acc, _opts), do: acc

  defp to_ast({:error, message, meta}, _template, _opts), do: {:error, message, meta}

  defp to_ast({:ok, tokens}, template, opts) do
    indentation = opts[:indentation]

    tokens_with_leading =
      case tokens do
        [{_type, _name, _attrs, %{column: col} = _meta} | _rest] = tokens
        when col - indentation > 1 ->
          leading_spaces = String.duplicate(" ", col - indentation - 1)
          [{:text, leading_spaces, %{column: 1, line: 1}} | tokens]

        tokens ->
          tokens
      end

    {ast, _remaining} = parse_nodes(tokens_with_leading, [], nil)

    nodes =
      case Keyword.get(opts, :trailing_whitespace, "") do
        "" -> ast
        trailing -> ast ++ [%Text{column: nil, content: "", line: nil, post: "", pre: trailing}]
      end

    {:ok, %__MODULE__{nodes: nodes, opts: opts, source: template}}
  rescue
    error in ParseError ->
      meta = %{column: error.column, line: error.line}
      {:error, error.message, meta}
  end

  defp parse_nodes([], acc, nil), do: {Enum.reverse(acc), []}

  defp parse_nodes([], _acc, {type, name, meta}) do
    raise ParseError,
      line: meta[:line],
      column: meta[:column],
      message: "expected closing tag #{format_close_tag(type, name)}"
  end

  defp parse_nodes([{:close, close_type, close_name, close_meta} | rest], acc, expected_close) do
    case expected_close do
      nil ->
        raise ParseError,
          line: close_meta[:line],
          column: close_meta[:column],
          message: "expected opening tag #{format_open_tag(close_type, close_name)}"

      {exp_type, exp_name, exp_meta} ->
        if tags_match?(close_type, close_name, exp_type, exp_name) do
          {Enum.reverse(acc), rest}
        else
          raise ParseError,
            line: close_meta[:line],
            column: close_meta[:column],
            message:
              "expected closing tag #{format_close_tag(exp_type, exp_name)} (opened on #{exp_meta[:line]}:#{exp_meta[:column]})\nbut got #{format_close_tag(close_type, close_name)}"
        end
    end
  end

  defp parse_nodes([{:text, content, meta} | rest], acc, expected_close) do
    {pre, trimmed, post} = extract_whitespace(content)

    node =
      if String.starts_with?(trimmed, "<!--") and String.ends_with?(trimmed, "-->") do
        comment_content =
          trimmed
          |> String.trim_leading("<!--")
          |> String.trim_trailing("-->")

        %HTMLComment{
          column: meta[:column],
          content: comment_content,
          line: meta[:line],
          post: post,
          pre: pre
        }
      else
        %Text{
          column: meta[:column],
          content: trimmed,
          line: meta[:line],
          post: post,
          pre: pre
        }
      end

    parse_nodes(rest, [node | acc], expected_close)
  end

  defp parse_nodes([{:eex_comment, content, meta} | rest], acc, expected_close) do
    node = %EExComment{
      column: meta[:column],
      content: content,
      line: meta[:line],
      post: "",
      pre: ""
    }

    parse_nodes(rest, [node | acc], expected_close)
  end

  defp parse_nodes([{:eex, _type, expr, meta} | rest], acc, expected_close) do
    node = %EExExpression{
      column: meta[:column],
      expression: expr,
      line: meta[:line],
      operator: meta[:opt] || "",
      post: "",
      pre: ""
    }

    parse_nodes(rest, [node | acc], expected_close)
  end

  defp parse_nodes([{:body_expr, expr, meta} | rest], acc, expected_close) do
    node = %Expression{
      column: meta[:column],
      expression: expr,
      line: meta[:line],
      post: "",
      pre: ""
    }

    parse_nodes(rest, [node | acc], expected_close)
  end

  defp parse_nodes([{:tag, tag, attrs, meta} | rest], acc, expected_close) do
    tag = String.downcase(tag)
    self_closing? = meta[:closing] in [:void, :self]

    {children, rest} =
      if self_closing? do
        {[], rest}
      else
        parse_nodes(rest, [], {:tag, tag, meta})
      end

    node = %Element{
      attributes: parse_attributes(attrs),
      children: children,
      column: meta[:column],
      line: meta[:line],
      post: "",
      pre: "",
      self_closing?: self_closing?,
      tag: tag
    }

    parse_nodes(rest, [node | acc], expected_close)
  end

  defp parse_nodes([{:local_component, name, attrs, meta} | rest], acc, expected_close) do
    self_closing? = meta[:closing] in [:void, :self]

    {children, rest} =
      if self_closing? do
        {[], rest}
      else
        parse_nodes(rest, [], {:local_component, name, meta})
      end

    node = %Component{
      attributes: parse_attributes(attrs),
      children: children,
      column: meta[:column],
      line: meta[:line],
      name: name,
      post: "",
      pre: "",
      self_closing?: self_closing?
    }

    parse_nodes(rest, [node | acc], expected_close)
  end

  defp parse_nodes([{:slot, slot_name, attrs, meta} | rest], acc, expected_close) do
    {children, remaining} = parse_nodes(rest, [], {:slot, slot_name, meta})

    node = %Slot{
      attributes: parse_attributes(attrs),
      children: children,
      column: meta[:column],
      line: meta[:line],
      name: slot_name,
      post: "",
      pre: ""
    }

    parse_nodes(remaining, [node | acc], expected_close)
  end

  defp tags_match?(:tag, close_name, :tag, open_name) do
    String.downcase(close_name) == open_name
  end

  defp tags_match?(type, name, type, name), do: true
  defp tags_match?(_, _, _, _), do: false

  defp format_close_tag(:tag, name), do: "</#{name}>"
  defp format_close_tag(:local_component, name), do: "</.#{name}>"
  defp format_close_tag(:slot, name), do: "</:#{name}>"

  defp format_open_tag(:tag, name), do: "<#{name}>"
  defp format_open_tag(:local_component, name), do: "<.#{name}>"
  defp format_open_tag(:slot, name), do: "<:#{name}>"

  defp extract_whitespace(content) do
    trimmed = String.trim(content)

    if trimmed == "" do
      {content, "", ""}
    else
      leading = Regex.run(~r/^\s*/, content) |> List.first() || ""
      trailing = Regex.run(~r/\s*$/, content) |> List.first() || ""
      {leading, trimmed, trailing}
    end
  end

  @doc """
  Parse and/or normalize attributes into AST.
  """
  def parse_attributes(attributes) when is_list(attributes) do
    attributes
    |> Enum.reduce([], fn attribute, acc ->
      attribute = parse_attribute(attribute)

      if attribute.value == false do
        acc
      else
        [attribute | acc]
      end
    end)
    |> Enum.reverse()
  end

  @doc """
  Parse and/or normalize an attribute into AST.
  """
  def parse_attribute(%Attribute{name: name} = attribute),
    do: normalize_attribute(%{attribute | name: String.downcase(name)})

  def parse_attribute({:root, {:expr, value, _expr_meta}, meta}) do
    %Attribute{
      column: Map.get(meta, :column),
      delimiter: nil,
      line: Map.get(meta, :line),
      name: "",
      type: :root,
      value: value
    }
  end

  def parse_attribute({name, value, meta}) do
    %Attribute{
      column: Map.get(meta, :column),
      line: Map.get(meta, :line),
      name: String.downcase(name),
      value: value
    }
    |> normalize_attribute()
  end

  defp normalize_attribute(%Attribute{value: nil} = attribute),
    do: %{attribute | delimiter: nil, type: :boolean, value: true}

  defp normalize_attribute(%Attribute{value: true} = attribute),
    do: %{attribute | delimiter: nil, type: :boolean, value: true}

  defp normalize_attribute(%Attribute{value: false} = attribute),
    do: %{attribute | delimiter: nil, type: :boolean, value: false}

  defp normalize_attribute(%Attribute{value: {:expr, value}} = attribute),
    do: %{attribute | delimiter: nil, type: :expression, value: value}

  defp normalize_attribute(%Attribute{value: {:expr, value, _meta}} = attribute),
    do: %{attribute | delimiter: nil, type: :expression, value: value}

  defp normalize_attribute(%Attribute{value: value} = attribute) when is_binary(value),
    do: normalize_attribute(%{attribute | value: {:string, value, %{}}})

  defp normalize_attribute(%Attribute{name: name, value: {:string, value, meta}} = attribute) do
    if name == String.downcase(value) || String.trim(value) == "" do
      %{attribute | delimiter: nil, type: :boolean, value: true}
    else
      %{attribute | delimiter: Map.get(meta, :delimiter, ?\"), value: value}
    end
  end
end
