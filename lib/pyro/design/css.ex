defmodule Pyro.Design.CSS do
  @moduledoc """
  CSS rendering helpers for `Pyro.Design`.

  Owns every "render this DTCG token/value as CSS" decision — value
  formatting, var-name generation, modifier dispatch resolution — for
  the design-level writer (`Pyro.Design.CSS.Writer`).
  """

  alias Pyro.Design.{Context, Group, Modifier, Reference, Token}

  @ext_namespace "pm.hex.pyro.css"
  @default_selector_template "[data-{modifier}=\"{context}\"]"

  @token_ref_re ~r/\$([a-z][a-z0-9_.]*[a-z0-9])(?:\/(\d+))?/

  @color_structs [
    Color.SRGB,
    Color.HSL,
    Color.Lab,
    Color.LCHab,
    Color.Oklab,
    Color.Oklch,
    Color.AdobeRGB,
    Color.RGB,
    Color.XYZ
  ]

  @doc """
  Turns a path of atom segments into a CSS custom-property name under
  the design's namespace.

      iex> Pyro.Design.CSS.var_name("pyro", [:color, :brand, :"500"])
      "--pyro-color-brand-500"
  """
  @spec var_name(String.t(), [atom()]) :: String.t()
  def var_name(namespace, path) when is_list(path) do
    "--#{namespace}-" <> Enum.map_join(path, "-", &dash/1)
  end

  @doc """
  Turns a dotted DTCG token reference (e.g. `"color.brand.500"`) into a
  CSS custom-property name. Equivalent to splitting and calling
  `var_name/2`.
  """
  @spec ref_to_css_var(String.t(), String.t()) :: String.t()
  def ref_to_css_var(ref, namespace) do
    path =
      ref
      |> String.split(".")
      |> Enum.map(&String.to_atom/1)

    var_name(namespace, path)
  end

  @doc """
  Renders a `%Pyro.Design.Token{}` to its CSS-side value. References
  lower to `var(--…)`, literal values to their typed CSS rendering.
  """
  @spec format_token(Token.t(), String.t()) :: String.t()
  def format_token(%Token{ref: %Reference{pointer: pointer}}, namespace) do
    "var(#{var_name(namespace, pointer)})"
  end

  def format_token(%Token{value: value}, _namespace), do: format_value(value)

  @doc """
  Renders a parsed DTCG value to a CSS-side string. Dispatches per
  type — colors via `Color.CSS.to_css/1`, dimensions and durations as
  `<n><unit>`, composites as their CSS shorthand.
  """
  @spec format_value(any()) :: String.t()
  def format_value(%struct{} = color) when struct in @color_structs,
    do: Color.CSS.to_css(color)

  def format_value({scalar, unit}) when is_number(scalar) and is_atom(unit),
    do: "#{format_number(scalar)}#{unit}"

  def format_value({a, b, c, d}) when is_number(a),
    do: "cubic-bezier(#{a}, #{b}, #{c}, #{d})"

  def format_value(n) when is_number(n), do: format_number(n)
  def format_value(b) when is_binary(b), do: b
  def format_value(a) when is_atom(a) and not is_nil(a), do: Atom.to_string(a)

  def format_value([%{color: _, position: _} | _] = stops) do
    inner =
      Enum.map_join(stops, ", ", fn %{color: c, position: p} ->
        "#{format_value(c)} #{format_position(p)}"
      end)

    "linear-gradient(#{inner})"
  end

  def format_value([first | _] = list) when is_binary(first),
    do: Enum.map_join(list, ", ", &~s("#{&1}"))

  def format_value(%{color: c, offset_x: ox, offset_y: oy, blur: bl, spread: sp}),
    do:
      "#{format_value(ox)} #{format_value(oy)} #{format_value(bl)} #{format_value(sp)} #{format_value(c)}"

  def format_value(%{color: c, width: w, style: s}),
    do: "#{format_value(w)} #{format_value(s)} #{format_value(c)}"

  def format_value(%{duration: d, delay: dl, timing_function: tf}),
    do: "#{format_value(d)} #{format_value(tf)} #{format_value(dl)}"

  def format_value(%{duration: d, timing_function: tf}),
    do: "#{format_value(d)} #{format_value(tf)}"

  def format_value(other), do: to_string(other)

  @doc """
  Returns `[{"<sub-property>", "<value>"}]` for a typography composite
  value. Typography has no CSS shorthand, so the writer emits one
  custom property per sub-field.
  """
  @spec format_typography(map()) :: [{String.t(), String.t()}]
  def format_typography(%{} = t) do
    [
      {"font-family", t[:font_family] && format_value(t.font_family)},
      {"font-size", t[:font_size] && format_value(t.font_size)},
      {"font-weight", t[:font_weight] && format_value(t.font_weight)},
      {"line-height", t[:line_height] && format_value(t.line_height)},
      {"letter-spacing", t[:letter_spacing] && format_value(t.letter_spacing)}
    ]
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
  end

  @doc """
  Returns `{selector_template_or_nil, media_query_or_nil}` for a
  modifier, applying defaults if the modifier carries no `pm.hex.pyro.css`
  `$extensions` entry.
  """
  @spec modifier_dispatch(Modifier.t()) :: {String.t() | nil, String.t() | nil}
  def modifier_dispatch(%Modifier{extensions: extensions}) do
    ext = Map.get(extensions || %{}, @ext_namespace, %{})
    template = Map.get(ext, "selector_template", @default_selector_template)
    media = Map.get(ext, "media_query_fallback")
    {template, media}
  end

  @doc """
  Substitutes `{modifier}` and `{context}` in a template. Returns
  `nil` if the template itself is `nil`.
  """
  @spec expand_template(String.t() | nil, atom(), atom()) :: String.t() | nil
  def expand_template(nil, _modifier, _context), do: nil

  def expand_template(template, modifier, context) when is_binary(template) do
    template
    |> String.replace("{modifier}", to_string(modifier))
    |> String.replace("{context}", to_string(context))
  end

  @doc """
  For each context of a modifier, returns the list of CSS variable
  overrides as `[{var_suffix, css_value}]` pairs (without leading `--`
  or namespace). Callers wrap them in the appropriate selector.
  """
  @spec modifier_overrides(Modifier.t(), String.t()) ::
          [{atom(), [{String.t(), String.t()}]}]
  def modifier_overrides(%Modifier{contexts: contexts}, namespace) do
    Enum.map(contexts || [], fn %Context{name: ctx_name, children: children} ->
      {ctx_name, collect_overrides(children || [], [], namespace)}
    end)
  end

  defp collect_overrides(nodes, prefix, namespace) do
    Enum.flat_map(nodes, fn
      %Token{name: name} = token ->
        suffix = Enum.map_join(prefix ++ [name], "-", &dash/1)
        [{suffix, format_token(token, namespace)}]

      %Group{name: name, children: children} ->
        collect_overrides(children || [], prefix ++ [name], namespace)
    end)
  end

  @doc """
  Resolves `$token.path` references inside a CSS value pattern to
  `var(--ns-…)` calls. Supports an optional `/<number>` opacity suffix
  that lowers to an `oklab(from <var> l a b / <alpha>)` expression.
  """
  @spec resolve_pattern(String.t(), String.t()) :: String.t()
  def resolve_pattern(value, namespace) do
    Regex.replace(@token_ref_re, value, fn _full, path, opacity_str ->
      var =
        case path do
          "token." <> name -> "var(--#{name})"
          _ -> "var(#{ref_to_css_var(path, namespace)})"
        end

      apply_opacity(var, opacity_str)
    end)
  end

  @doc """
  The compiled regex used to match `$token.path` references in CSS
  source. Captures the dotted path and an optional `/opacity` suffix.
  """
  @spec token_ref_regex() :: Regex.t()
  def token_ref_regex, do: @token_ref_re

  @doc """
  Returns every `$token.path` reference in `css` as a list of
  `%{raw, path, opacity}` maps. `path` is split into atom segments;
  `opacity` is the parsed integer suffix or `nil`.
  """
  @spec walk_refs(String.t()) :: [%{raw: String.t(), path: [atom()], opacity: integer() | nil}]
  def walk_refs(css) do
    @token_ref_re
    |> Regex.scan(css)
    |> Enum.map(fn
      [raw, path, opacity_str] ->
        %{raw: raw, path: split_path(path), opacity: parse_opacity(opacity_str)}

      [raw, path] ->
        %{raw: raw, path: split_path(path), opacity: nil}
    end)
  end

  @doc """
  Resolves all `$token.path` references in a CSS source against
  `design`. Refs inside `@media` query conditions substitute the
  token's literal value (since `var()` is invalid in media query
  conditions). Refs elsewhere lower to `var(--<namespace>-<path>)`.
  """
  @spec resolve_in_css(String.t(), module()) :: String.t()
  def resolve_in_css(css, design) do
    namespace = Pyro.Design.Info.namespace(design)
    tokens = Pyro.Design.Info.tokens(design)

    css
    |> rewrite_media_conditions(tokens)
    |> resolve_pattern(namespace)
  end

  defp rewrite_media_conditions(css, tokens) do
    Regex.replace(~r/@media[^{]*/, css, fn segment ->
      Regex.replace(@token_ref_re, segment, fn _full, path, _opacity ->
        path_atoms = split_path(path)

        case Map.get(tokens, path_atoms) do
          %Token{value: value} when not is_nil(value) ->
            format_value(value)

          _ ->
            # Validator catches missing/ref-only tokens before this runs.
            "$" <> path
        end
      end)
    end)
  end

  defp split_path(path) when is_binary(path) do
    path |> String.split(".") |> Enum.map(&String.to_atom/1)
  end

  defp parse_opacity(""), do: nil

  defp parse_opacity(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, ""} -> n
      _ -> nil
    end
  end

  @doc """
  Returns a `%{var-suffix => css-value}` map for every token in the
  design — used to substitute `$ref` patterns in selector strings with
  their resolved literal values.
  """
  @spec build_token_literal_map(module()) :: %{String.t() => String.t()}
  def build_token_literal_map(design_module) do
    namespace = Pyro.Design.Info.namespace(design_module)

    design_module
    |> Pyro.Design.Info.tokens()
    |> Map.new(fn {path, token} ->
      suffix = Enum.map_join(path, "-", &dash/1)
      {suffix, format_token(token, namespace)}
    end)
  end

  defp apply_opacity(var, nil), do: var
  defp apply_opacity(var, ""), do: var

  defp apply_opacity(var, str) do
    case Float.parse(str) do
      {alpha, ""} when alpha > 1.0 -> "oklab(from #{var} l a b / #{alpha / 100})"
      {alpha, ""} when alpha == 1.0 -> var
      {alpha, ""} -> "oklab(from #{var} l a b / #{alpha})"
      _ -> var
    end
  end

  defp format_number(n) when is_integer(n), do: Integer.to_string(n)

  defp format_number(n) when is_float(n) do
    truncated = trunc(n)
    if n == truncated, do: Integer.to_string(truncated), else: Float.to_string(n)
  end

  defp format_position(p) when is_number(p), do: "#{format_number(p * 100)}%"
  defp format_position(other), do: to_string(other)

  defp dash(name) when is_atom(name), do: name |> Atom.to_string() |> String.replace("_", "-")
  defp dash(name) when is_binary(name), do: String.replace(name, "_", "-")
end
