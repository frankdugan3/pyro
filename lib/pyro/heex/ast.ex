defmodule Pyro.HEEx.AST do
  @moduledoc """
  Tooling to parse HEEx into AST, and from AST to HEEx.
  """
  defstruct context: %{}, nodes: []

  @type t :: %__MODULE__{
          context: map(),
          nodes: [ast_node()]
        }

  @type ast_node ::
          {:element, tag_name :: String.t(), attributes :: [attribute()],
           children :: [ast_node()]}
          | {:text, content :: String.t()}
          | {:comment, content :: String.t()}
          | {:eex_expr, operator :: String.t(), content :: String.t()}
          | {:eex_expr, content :: String.t()}
          | heex_expr()

  @type heex_expr :: {:heex_expr, content :: String.t()}
  @type attribute :: {key :: String.t(), value :: String.t() | heex_expr()}

  @doc """
  Encodes a list of AST nodes back into a HEEx string.
  """
  @spec encode_node([ast_node()]) :: String.t()
  def encode_nodes(nodes) do
    Enum.map_join(nodes, &encode_node/1)
  end

  @doc """
  Encodes an AST node back into a HEEx string.
  """
  @spec encode_node(ast_node()) :: String.t()
  def encode_node({:text, content}), do: content
  def encode_node({:comment, content}), do: "<!--#{content}-->"
  def encode_node({:eex_expr, tag, content}), do: "<%#{tag}#{content}%>"
  def encode_node({:heex_expr, content}), do: "{#{content}}"

  def encode_node({:element, tag_name, attributes, children}) do
    attr_string = encode_attributes(attributes)

    if Enum.empty?(children) do
      "<#{tag_name}#{attr_string} />"
    else
      children_string = Enum.map_join(children, &encode_node/1)
      "<#{tag_name}#{attr_string}>#{children_string}</#{tag_name}>"
    end
  end

  @doc """
  Encodes the AST of attributes into a HEEx string.
  """
  @spec encode_attributes([attribute()]) :: String.t()
  def encode_attributes(attributes) do
    Enum.map_join(attributes, fn
      {key, string_boolean} when string_boolean in ["true", "false"] ->
        raise ArgumentError,
              ~s[#{key}=#{inspect(string_boolean)} is an invalid boolean attribute value.]

      {key, truthy} when key == truthy or truthy in [true, ""] ->
        " #{key}"

      {_key, falsey} when falsey in [nil, false] ->
        ""

      {key, {:heex_expr, content}} ->
        " #{key}={#{content}}"

      {key, value} ->
        " #{key}=\"#{value}\""
    end)
  end

  @doc """
  Parses HEEx template string into an AST.
  """
  @spec parse_template!(String.t()) :: t()
  def parse_template!(template), do: parse_template!(template, [])

  defp parse_template!("", acc) do
    %__MODULE__{nodes: Enum.reverse(acc)}
  end

  defp parse_template!(template, acc) do
    case parse_single_node(template) do
      {{:close_tag, tag_name, remaining}, _} ->
        {:close_tag, tag_name, remaining, Enum.reverse(acc)}

      {node, remaining} ->
        parse_template!(remaining, [node | acc])
    end
  end

  defp parse_template_until_close("", expected_tag, _acc) do
    {:error, "Missing closing tag for <#{expected_tag}>"}
  end

  defp parse_template_until_close("</" <> rest, expected_tag, acc) do
    {tag_content, remaining} = extract_until_char(rest, ">")
    tag_name = String.trim(tag_content)

    if tag_name == expected_tag do
      {:found_close, Enum.reverse(acc), remaining}
    else
      {:error, "Mismatched closing tag: expected </#{expected_tag}>, got </#{tag_name}>"}
    end
  end

  defp parse_template_until_close(template, expected_tag, acc) do
    case parse_single_node(template) do
      {node, remaining} ->
        parse_template_until_close(remaining, expected_tag, [node | acc])
    end
  end

  defp parse_single_node(template) do
    case detect_node_type(template) do
      {:eex_expr, operator, rest} ->
        parse_eex_expression(rest, operator)

      {:heex_expr, rest} ->
        parse_heex_expression(rest)

      {:html_comment, rest} ->
        parse_html_comment(rest)

      {:closing_tag, rest} ->
        parse_closing_tag(rest)

      {:html_tag, rest} ->
        parse_html_tag(rest)

      {:text, _} ->
        parse_text_content(template)
    end
  end

  defp detect_node_type("<%=" <> rest), do: {:eex_expr, "=", rest}
  defp detect_node_type("<%%" <> rest), do: {:eex_expr, "%", rest}
  defp detect_node_type("<%!--" <> rest), do: {:eex_expr, "!--", rest}
  defp detect_node_type("<%" <> rest), do: {:eex_expr, "", rest}
  defp detect_node_type("{" <> rest), do: {:heex_expr, rest}
  defp detect_node_type("<!--" <> rest), do: {:html_comment, rest}
  defp detect_node_type("</" <> rest), do: {:closing_tag, rest}

  defp detect_node_type("<" <> rest) do
    case categorize_angle_bracket_content(rest) do
      :is_tag ->
        {:html_tag, rest}

      :is_text ->
        {:text, "<" <> rest}
    end
  end

  defp detect_node_type(template), do: {:text, template}

  defp parse_eex_expression(rest, operator) do
    {expr_content, remaining} = extract_until_pattern(rest, "%>")
    {{:eex_expr, operator, expr_content}, remaining}
  end

  defp parse_heex_expression(rest) do
    {expr_content, remaining} = extract_balanced_braces(rest, 1, "")
    {{:heex_expr, expr_content}, remaining}
  end

  defp parse_html_comment(rest) do
    {comment_content, remaining} = extract_until_pattern(rest, "-->")
    {{:comment, comment_content}, remaining}
  end

  defp parse_closing_tag(rest) do
    {tag_content, remaining} = extract_until_char(rest, ">")
    tag_name = String.trim(tag_content)
    {{:close_tag, tag_name, remaining}, ""}
  end

  defp parse_html_tag(rest) do
    {tag_content, remaining} = extract_until_char(rest, ">")

    case classify_html_tag(tag_content) do
      {:self_closing, tag_content_trimmed} ->
        parse_self_closing_tag(tag_content_trimmed, remaining)

      {:opening, tag_content} ->
        parse_opening_tag(tag_content, remaining)
    end
  end

  defp parse_text_content(template) do
    {text_content, remaining} = extract_text_content(template)

    if text_content == "" do
      case template do
        <<char::utf8, rest::binary>> ->
          {{:text, <<char::utf8>>}, rest}

        "" ->
          {{:text, ""}, ""}
      end
    else
      {{:text, text_content}, remaining}
    end
  end

  defp classify_html_tag(tag_content) do
    if String.ends_with?(tag_content, "/") do
      tag_content_trimmed =
        String.slice(tag_content, 0, String.length(tag_content) - 1) |> String.trim()

      {:self_closing, tag_content_trimmed}
    else
      {:opening, tag_content}
    end
  end

  defp parse_self_closing_tag(tag_content_trimmed, remaining) do
    {tag_name, attributes} = parse_tag_and_attributes(tag_content_trimmed)
    element = {:element, String.downcase(tag_name), attributes, []}
    {element, remaining}
  end

  defp parse_opening_tag(tag_content, remaining) do
    {tag_name, attributes} = parse_tag_and_attributes(tag_content)

    case parse_template_until_close(remaining, tag_name, []) do
      {:found_close, children, remaining_after} ->
        element = {:element, String.downcase(tag_name), attributes, children}
        {element, remaining_after}

      {:error, msg} ->
        raise ArgumentError, msg
    end
  end

  defp extract_until_pattern(string, pattern) do
    case String.split(string, pattern, parts: 2) do
      [content, remaining] ->
        {content, remaining}

      [content] ->
        cond do
          pattern == "%>" ->
            raise ArgumentError, "Unclosed EEx expression"

          pattern == "-->" ->
            raise ArgumentError, "Unclosed HTML comment"

          true ->
            {content, ""}
        end
    end
  end

  defp extract_balanced_braces("", 0, acc), do: {acc, ""}

  defp extract_balanced_braces("", _depth, _acc),
    do: raise(ArgumentError, "Unclosed HEEx expression")

  defp extract_balanced_braces("}" <> rest, 1, acc) do
    {acc, rest}
  end

  defp extract_balanced_braces("{" <> rest, depth, acc) do
    extract_balanced_braces(rest, depth + 1, acc <> "{")
  end

  defp extract_balanced_braces("}" <> rest, depth, acc) when depth > 1 do
    extract_balanced_braces(rest, depth - 1, acc <> "}")
  end

  defp extract_balanced_braces(<<char::utf8, rest::binary>>, depth, acc) do
    extract_balanced_braces(rest, depth, acc <> <<char::utf8>>)
  end

  defp extract_until_char(string, target_char) do
    case String.split(string, target_char, parts: 2) do
      [content, remaining] -> {content, remaining}
      [content] -> {content, ""}
    end
  end

  defp extract_text_content(string) do
    extract_text_content(string, "")
  end

  defp extract_text_content("", acc), do: {acc, ""}

  defp extract_text_content(string, acc) do
    case detect_node_type(string) do
      {:text, _} ->
        case string do
          <<char::utf8, rest::binary>> ->
            extract_text_content(rest, acc <> <<char::utf8>>)

          "" ->
            {acc, ""}
        end

      _ ->
        {acc, string}
    end
  end

  defp categorize_angle_bracket_content(rest) do
    case find_tag_end(rest, 0, "") do
      {:found, possible_tag, _remaining} ->
        case consume_tag_name(possible_tag, "") do
          {tag_name, _rest} when tag_name != "" ->
            if String.match?(tag_name, ~r/^[a-zA-Z\.\:]/) do
              :is_tag
            else
              :is_text
            end

          _ ->
            :is_text
        end

      :not_found ->
        :is_text
    end
  end

  defp find_tag_end("", _brace_depth, _acc), do: :not_found

  defp find_tag_end(">" <> rest, 0, acc) do
    {:found, acc, rest}
  end

  defp find_tag_end(">" <> rest, brace_depth, acc) when brace_depth > 0 do
    find_tag_end(rest, brace_depth, acc <> ">")
  end

  defp find_tag_end("{" <> rest, brace_depth, acc) do
    find_tag_end(rest, brace_depth + 1, acc <> "{")
  end

  defp find_tag_end("}" <> rest, brace_depth, acc) when brace_depth > 0 do
    find_tag_end(rest, brace_depth - 1, acc <> "}")
  end

  defp find_tag_end(<<char::utf8, rest::binary>>, brace_depth, acc) do
    find_tag_end(rest, brace_depth, acc <> <<char::utf8>>)
  end

  defp parse_tag_and_attributes(tag_content) do
    tag_content = String.trim(tag_content)

    case consume_tag_name(tag_content, "") do
      {tag_name, ""} ->
        {tag_name, []}

      {tag_name, remaining} ->
        attributes = parse_attributes_lexer(remaining, [])
        {tag_name, attributes}
    end
  end

  defp consume_tag_name("", acc), do: {acc, ""}

  defp consume_tag_name(<<char::utf8, rest::binary>>, acc) when char in [?\s, ?\t, ?\n, ?\r] do
    {acc, <<char::utf8, rest::binary>>}
  end

  defp consume_tag_name(<<char::utf8, rest::binary>>, acc) do
    consume_tag_name(rest, acc <> <<char::utf8>>)
  end

  defp parse_attributes_lexer("", acc), do: Enum.reverse(acc)

  defp parse_attributes_lexer(string, acc) do
    case String.trim(string) do
      "" ->
        Enum.reverse(acc)

      attribute ->
        case consume_attribute(attribute) do
          {key, value, remaining} ->
            parse_attributes_lexer(remaining, [{key, value} | acc])

          :error ->
            handle_invalid_attribute(attribute, acc)
        end
    end
  end

  defp handle_invalid_attribute(string, acc) do
    case String.split(string, ~r/\s+/, parts: 2) do
      [_invalid, remaining] -> parse_attributes_lexer(remaining, acc)
      [_] -> Enum.reverse(acc)
    end
  end

  defp consume_attribute(string) do
    case consume_attribute_name(string, "") do
      {key, "=" <> rest} ->
        case consume_attribute_value(rest) do
          {"", remaining} ->
            {key, true, remaining}

          {value, remaining} when is_binary(value) ->
            value = if String.downcase(value) == key, do: true, else: value
            {key, value, remaining}

          {value, remaining} ->
            {key, value, remaining}

          :error ->
            :error
        end

      {key, remaining} ->
        {key, true, String.trim(remaining)}
    end
  end

  defp consume_attribute_name("", acc), do: {String.downcase(acc), ""}
  defp consume_attribute_name("=" <> rest, acc), do: {String.downcase(acc), "=" <> rest}

  defp consume_attribute_name(<<char::utf8, rest::binary>>, acc)
       when char in [?\s, ?\t, ?\n, ?\r] do
    {String.downcase(acc), rest}
  end

  defp consume_attribute_name(<<char::utf8, rest::binary>>, acc) do
    consume_attribute_name(rest, acc <> <<char::utf8>>)
  end

  defp consume_attribute_value("\"" <> rest) do
    consume_quoted_value(rest, "\"", "")
  end

  defp consume_attribute_value("'" <> rest) do
    consume_quoted_value(rest, "'", "")
  end

  defp consume_attribute_value("{" <> rest) do
    {value, remaining} = extract_balanced_braces(rest, 1, "")
    {{:heex_expr, value}, remaining}
  end

  defp consume_attribute_value(string) do
    consume_unquoted_value(string, "")
  end

  defp consume_quoted_value("", _quote, _acc), do: :error

  defp consume_quoted_value(string, quote, acc) do
    case String.starts_with?(string, quote) do
      true ->
        remaining = String.slice(string, String.length(quote), String.length(string))
        {acc, remaining}

      false ->
        case string do
          <<char::utf8, rest::binary>> ->
            consume_quoted_value(rest, quote, acc <> <<char::utf8>>)

          _ ->
            :error
        end
    end
  end

  defp consume_unquoted_value("", acc), do: {acc, ""}

  defp consume_unquoted_value(<<char::utf8, rest::binary>>, acc)
       when char in [?\s, ?\t, ?\n, ?\r] do
    {acc, <<char::utf8, rest::binary>>}
  end

  defp consume_unquoted_value(<<char::utf8, rest::binary>>, acc) do
    consume_unquoted_value(rest, acc <> <<char::utf8>>)
  end
end
