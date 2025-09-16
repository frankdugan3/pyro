defmodule Pyro.HeexParser do
  @moduledoc """
  A simple parser for HEEx template strings.

  The purpose is to enable Pyro to transform HTML attributes, so interpolated Elixir is not parsed. It's basically an HTML parser that can ignore and preserve HEEx/EEx interpolation.
  """

  @type ast_node ::
          {:element, tag_name :: String.t(), attributes :: [attribute()],
           children :: [ast_node()]}
          | {:text, content :: String.t()}
          | {:comment, content :: String.t()}
          | {:eex_expr, tag :: String.t(), content :: String.t()}
          | {:eex_expr, content :: String.t()}
          | heex_expr()

  @type heex_expr :: {:heex_expr, content :: String.t()}
  @type attribute ::
          {key :: String.t(), value :: String.t() | heex_expr(), whitespace :: String.t()}

  @doc """
  Parses a HEEx template string into an AST.

  ## Examples

      iex> parse("<div>Hello</div>")
      {:ok, [{:element, "div", [], [{:text, "Hello"}]}]}

      iex> parse("<p class='bold'>{@name}</p>")
      {:ok, [{:element, "p", [{"class", "bold", " "}], [{:heex_expr, "@name"}]}]}
  """
  @spec parse(String.t()) :: {:ok, [ast_node()]} | {:error, String.t()}
  def parse(template) when is_binary(template) do
    try do
      ast = parse_template(template, [])
      {:ok, ast}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Encodes an AST back into a HEEx template string.

  ## Examples

      iex> ast = [{:element, "div", [], [{:text, "Hello"}]}]
      iex> encode(ast)
      "<div>Hello</div>"
  """
  @spec encode([ast_node()] | ast_node()) :: String.t()
  def encode(ast) when is_list(ast) do
    Enum.map_join(ast, &encode_node/1)
  end

  def encode(node), do: encode_node(node)

  @doc """
  Tallies attribute values in the AST for a given attribute pattern.

  Supports exact attribute names or wildcard patterns ending with '*'.
  Boolean attributes are counted as having a true value.
  HEEx expressions in attribute values are converted to strings.

  Returns a map where keys are attribute names found, and values are maps
  containing each unique value as a key with its occurrence count as the value.

  ## Examples

      iex> ast = [{:element, "div", [{"pyro-component", "button", " "}, {"disabled", "disabled", " "}], []}]
      iex> tally_attributes(ast, "pyro-component")
      %{"pyro-component" => %{"button" => 1}}

      iex> ast = [
      ...>   {:element, "div", [{"pyro-test", "value1", " "}], []},
      ...>   {:element, "span", [{"pyro-test", "value2", " "}, {"pyro-other", "value3", " "}], []}
      ...> ]
      iex> tally_attributes(ast, "pyro-*")
      %{"pyro-test" => %{"value1" => 1, "value2" => 1}, "pyro-other" => %{"value3" => 1}}

      iex> ast = [{:element, "input", [{"required", "required", " "}, {"disabled", "disabled", " "}], []}]
      iex> tally_attributes(ast, "required")
      %{"required" => %{true => 1}}
  """
  @spec tally_attributes([ast_node()] | ast_node(), String.t()) :: %{
          String.t() => %{any() => non_neg_integer()}
        }
  def tally_attributes(ast, attribute_pattern) when is_binary(attribute_pattern) do
    is_wildcard = String.ends_with?(attribute_pattern, "*")

    pattern_prefix =
      if is_wildcard, do: String.slice(attribute_pattern, 0..-2//1), else: attribute_pattern

    ast
    |> List.wrap()
    |> traverse_for_attributes(%{}, is_wildcard, pattern_prefix)
  end

  defp traverse_for_attributes([], acc, _is_wildcard, _pattern_prefix), do: acc

  defp traverse_for_attributes([node | rest], acc, is_wildcard, pattern_prefix) do
    updated_acc = traverse_node_for_attributes(node, acc, is_wildcard, pattern_prefix)
    traverse_for_attributes(rest, updated_acc, is_wildcard, pattern_prefix)
  end

  defp traverse_node_for_attributes(
         {:element, _tag_name, attributes, children},
         acc,
         is_wildcard,
         pattern_prefix
       ) do
    # Process attributes for this element
    attr_acc = process_attributes(attributes, acc, is_wildcard, pattern_prefix)

    # Recursively process children
    traverse_for_attributes(children, attr_acc, is_wildcard, pattern_prefix)
  end

  defp traverse_node_for_attributes(_other_node, acc, _is_wildcard, _pattern_prefix) do
    # For text, comments, eex_expr, heex_expr nodes, just return the accumulator unchanged
    acc
  end

  defp process_attributes([], acc, _is_wildcard, _pattern_prefix), do: acc

  defp process_attributes(
         [{attr_name, attr_value, _whitespace} | rest],
         acc,
         is_wildcard,
         pattern_prefix
       ) do
    updated_acc =
      if attribute_matches?(attr_name, is_wildcard, pattern_prefix) do
        processed_value = process_attribute_value(attr_name, attr_value)
        increment_count(acc, attr_name, processed_value)
      else
        acc
      end

    process_attributes(rest, updated_acc, is_wildcard, pattern_prefix)
  end

  defp attribute_matches?(attr_name, true, pattern_prefix) do
    String.starts_with?(attr_name, pattern_prefix)
  end

  defp attribute_matches?(attr_name, false, exact_name) do
    attr_name == exact_name
  end

  defp process_attribute_value(attr_name, attr_value) do
    case attr_value do
      # Boolean attribute (key == value)
      ^attr_name -> true
      # HEEx expression - convert to string representation
      {:heex_expr, content} -> content
      # Regular string value
      value when is_binary(value) -> value
      # Fallback for any other type
      other -> to_string(other)
    end
  end

  defp increment_count(acc, attr_name, value) do
    Map.update(acc, attr_name, %{value => 1}, fn attr_map ->
      Map.update(attr_map, value, 1, &(&1 + 1))
    end)
  end

  defp parse_template("", acc) do
    Enum.reverse(acc)
  end

  defp parse_template(template, acc) do
    case parse_single_node(template) do
      {{:close_tag, tag_name, remaining}, _} ->
        {:close_tag, tag_name, remaining, Enum.reverse(acc)}

      {node, remaining} ->
        parse_template(remaining, [node | acc])
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

  # Detect what type of node we're looking at
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

    if text_content != "" do
      {{:text, text_content}, remaining}
    else
      case template do
        <<char::utf8, rest::binary>> ->
          {{:text, <<char::utf8>>}, rest}

        "" ->
          {{:text, ""}, ""}
      end
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
    element = {:element, tag_name, attributes, []}
    {element, remaining}
  end

  defp parse_opening_tag(tag_content, remaining) do
    {tag_name, attributes} = parse_tag_and_attributes(tag_content)

    case parse_template_until_close(remaining, tag_name, []) do
      {:found_close, children, remaining_after} ->
        element = {:element, tag_name, attributes, children}
        {element, remaining_after}

      {:error, msg} ->
        raise msg
    end
  end

  defp extract_until_pattern(string, pattern) do
    case String.split(string, pattern, parts: 2) do
      [content, remaining] ->
        {content, remaining}

      [content] ->
        cond do
          pattern == "%>" ->
            raise "Unclosed EEx expression"

          pattern == "-->" ->
            raise "Unclosed HTML comment"

          true ->
            {content, ""}
        end
    end
  end

  defp extract_balanced_braces("", 0, acc), do: {acc, ""}
  defp extract_balanced_braces("", _depth, _acc), do: raise("Unclosed HEEx expression")

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
    case String.split(rest, ">", parts: 2) do
      [possible_tag, _] ->
        if String.match?(possible_tag, ~r/^[a-zA-Z\/\.:][\w\s\-\.:"'=@{}\/]*$/) do
          :is_tag
        else
          :is_text
        end

      [_] ->
        :is_text
    end
  end

  defp parse_tag_and_attributes(tag_content) do
    tag_content = String.trim(tag_content)

    case consume_tag_name(tag_content, "") do
      {tag_name, ""} ->
        {tag_name, []}

      {tag_name, remaining} ->
        # Don't trim the leading whitespace - preserve it for the first attribute
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
    {whitespace, string_without_ws} = extract_leading_whitespace(string)

    case string_without_ws do
      "" ->
        Enum.reverse(acc)

      _ ->
        case consume_attribute(string_without_ws) do
          {key, value, remaining} ->
            parse_attributes_lexer(remaining, [{key, value, whitespace} | acc])

          :error ->
            # Skip invalid attribute and continue
            case String.split(string_without_ws, ~r/\s+/, parts: 2) do
              [_invalid, remaining] -> parse_attributes_lexer(remaining, acc)
              [_] -> Enum.reverse(acc)
            end
        end
    end
  end

  defp extract_leading_whitespace(string) do
    extract_leading_whitespace(string, "")
  end

  defp extract_leading_whitespace("", acc), do: {acc, ""}

  defp extract_leading_whitespace(<<char::utf8, rest::binary>>, acc)
       when char in [?\s, ?\t, ?\n, ?\r] do
    extract_leading_whitespace(rest, acc <> <<char::utf8>>)
  end

  defp extract_leading_whitespace(string, acc), do: {acc, string}

  defp consume_attribute(string) do
    case consume_attribute_name(string, "") do
      # Valued
      {key, "=" <> rest} ->
        case consume_attribute_value(rest) do
          {value, remaining} -> {key, value, remaining}
          :error -> :error
        end

      # Boolean
      {key, remaining} ->
        remaining = skip_whitespace(remaining)
        {key, key, remaining}
    end
  end

  defp consume_attribute_name("", acc), do: {acc, ""}
  defp consume_attribute_name("=" <> rest, acc), do: {acc, "=" <> rest}

  defp consume_attribute_name(<<char::utf8, rest::binary>>, acc)
       when char in [?\s, ?\t, ?\n, ?\r] do
    {acc, skip_whitespace(<<char::utf8, rest::binary>>)}
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
    case extract_balanced_braces(rest, 1, "") do
      {value, remaining} -> {{:heex_expr, value}, remaining}
      _ -> :error
    end
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

  defp skip_whitespace(""), do: ""

  defp skip_whitespace(<<char::utf8, rest::binary>>) when char in [?\s, ?\t, ?\n, ?\r] do
    skip_whitespace(rest)
  end

  defp skip_whitespace(string), do: string

  defp encode_node({:text, content}), do: content
  defp encode_node({:comment, content}), do: "<!--#{content}-->"
  defp encode_node({:eex_expr, tag, content}), do: "<%#{tag}#{content}%>"
  defp encode_node({:heex_expr, content}), do: "{#{content}}"

  defp encode_node({:element, tag_name, attributes, children}) do
    attr_string = encode_attributes(attributes)

    if Enum.empty?(children) do
      "<#{tag_name}#{attr_string} />"
    else
      children_string = Enum.map_join(children, &encode_node/1)
      "<#{tag_name}#{attr_string}>#{children_string}</#{tag_name}>"
    end
  end

  defp encode_attributes(attributes) do
    Enum.map_join(attributes, fn
      {key, value, whitespace} when key == value ->
        ws = if whitespace == "", do: " ", else: whitespace
        "#{ws}#{key}"

      {key, {:heex_expr, content}, whitespace} ->
        ws = if whitespace == "", do: " ", else: whitespace
        "#{ws}#{key}={#{content}}"

      {key, value, whitespace} ->
        ws = if whitespace == "", do: " ", else: whitespace
        "#{ws}#{key}=\"#{value}\""
    end)
  end
end
