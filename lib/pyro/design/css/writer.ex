defmodule Pyro.Design.CSS.Writer do
  @moduledoc false

  alias Pyro.Design.{CSS, Info, Modifier, Property, Raw, Selector}

  def write(design_module) do
    path = Info.css_output(design_module)

    if path do
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, build(design_module))
    end

    :ok
  end

  def build(design_module) do
    namespace = Info.namespace(design_module)

    [
      tailwind_preamble_section(design_module),
      tailwind_theme_section(design_module, namespace),
      root_section(design_module, namespace),
      modifier_sections(design_module, namespace),
      base_layer_section(design_module, namespace),
      icons_section(design_module, namespace)
    ]
    |> Enum.reject(&blank?/1)
    |> Enum.join("\n\n")
    |> Kernel.<>("\n")
  end

  defp tailwind_preamble_section(design_module) do
    if Info.support_tailwind?(design_module) do
      Info.tailwind_preamble(design_module)
    end
  end

  defp tailwind_theme_section(design_module, namespace) do
    if Info.support_tailwind?(design_module) do
      lines = tailwind_theme_lines(design_module, namespace)
      wrap_block("@theme", lines)
    end
  end

  # Tailwind v4's `@theme` directive expects un-namespaced names in a
  # fixed set of namespaces (`--color-*`, `--spacing-*`, `--radius-*`,
  # `--shadow-*`, `--blur-*`, `--ease-*`, `--breakpoint-*`, `--text-*`,
  # `--font-weight-*`). Tokens that don't map to one of those are
  # skipped — they remain accessible as `--<ns>-…` custom properties
  # via the `:root` block, just not as Tailwind-utility-generating
  # entries.
  defp tailwind_theme_lines(design_module, namespace) do
    modifier_paths = design_module |> Info.modifiers() |> Map.keys()

    design_module
    |> Info.tokens()
    |> Enum.reject(fn {path, _token} -> under_any?(path, modifier_paths) end)
    |> Enum.sort()
    |> Enum.flat_map(fn {path, _token} ->
      case tailwind_theme_key(path) do
        nil -> []
        key -> ["#{key}: var(#{CSS.var_name(namespace, path)});"]
      end
    end)
  end

  defp tailwind_theme_key([:color | rest]), do: "--color-" <> dash_join(rest)
  defp tailwind_theme_key([:spacing | rest]), do: "--spacing-" <> dash_join(rest)
  defp tailwind_theme_key([:radius | rest]), do: "--radius-" <> dash_join(rest)
  defp tailwind_theme_key([:shadow | rest]), do: "--shadow-" <> dash_join(rest)
  defp tailwind_theme_key([:blur | rest]), do: "--blur-" <> dash_join(rest)
  defp tailwind_theme_key([:easing | rest]), do: "--ease-" <> dash_join(rest)
  defp tailwind_theme_key([:breakpoint | rest]), do: "--breakpoint-" <> dash_join(rest)
  defp tailwind_theme_key([:font, :size | rest]), do: "--text-" <> dash_join(rest)
  defp tailwind_theme_key([:font, :weight | rest]), do: "--font-weight-" <> dash_join(rest)
  defp tailwind_theme_key(_), do: nil

  defp dash_join(segments) do
    Enum.map_join(segments, "-", fn name ->
      name |> Atom.to_string() |> String.replace("_", "-")
    end)
  end

  defp root_section(design_module, namespace) do
    vars = root_vars(design_module, namespace)
    wrap_block(":root", vars)
  end

  defp root_vars(design_module, namespace) do
    modifier_paths = design_module |> Info.modifiers() |> Map.keys()

    design_module
    |> Info.tokens()
    |> Enum.reject(fn {path, _token} -> under_any?(path, modifier_paths) end)
    |> Enum.sort()
    |> Enum.map(fn {path, token} ->
      "#{CSS.var_name(namespace, path)}: #{CSS.format_token(token, namespace)};"
    end)
  end

  defp under_any?(path, modifier_paths) do
    Enum.any?(modifier_paths, fn mod_path ->
      List.starts_with?(path, mod_path)
    end)
  end

  defp modifier_sections(design_module, namespace) do
    design_module
    |> Info.modifiers()
    |> Enum.sort()
    |> Enum.flat_map(fn {_path, mod} -> modifier_blocks(mod, namespace) end)
    |> Enum.join("\n\n")
  end

  defp modifier_blocks(%Modifier{name: mod_name, default: default_ctx} = mod, namespace) do
    {selector_template, media_template} = CSS.modifier_dispatch(mod)
    overrides = CSS.modifier_overrides(mod, namespace)

    Enum.flat_map(overrides, fn
      {^default_ctx, _vars} ->
        []

      {_ctx, []} ->
        []

      {ctx_name, vars} ->
        var_lines = Enum.map(vars, &var_line(&1, namespace))

        selector_block =
          case CSS.expand_template(selector_template, mod_name, ctx_name) do
            nil -> nil
            selector -> wrap_block(selector, var_lines)
          end

        media_block =
          case CSS.expand_template(media_template, mod_name, ctx_name) do
            nil -> nil
            media -> wrap_block(media, [wrap_block(":root", var_lines)])
          end

        [selector_block, media_block] |> Enum.reject(&is_nil/1)
    end)
  end

  defp base_layer_section(design_module, namespace) do
    if Info.manage_base_layer?(design_module) do
      blocks =
        design_module
        |> Info.base_layer_blocks()
        |> Enum.map(&base_layer_block(&1, design_module, namespace))
        |> Enum.reject(&is_nil/1)

      case blocks do
        [] -> nil
        _ -> wrap_block("@layer base", blocks)
      end
    end
  end

  defp base_layer_block(%Selector{} = sel, _design_module, namespace),
    do: selector_block(sel, namespace)

  defp base_layer_block(%Raw{css: css}, design_module, _namespace),
    do: CSS.resolve_in_css(css, design_module)

  defp icons_section(design_module, namespace) do
    case Info.icon_map(design_module) do
      empty when map_size(empty) == 0 ->
        nil

      icons ->
        icons
        |> Enum.sort()
        |> Enum.map_join("\n\n", fn {name, svg} ->
          "[data-#{namespace}-icon=\"#{name}\"] {\n  mask-image: url(\"#{svg_to_data_uri(svg)}\");\n}"
        end)
    end
  end

  defp svg_to_data_uri(svg) do
    encoded =
      svg
      |> String.trim()
      |> String.replace("\"", "'")
      |> String.replace("#", "%23")
      |> String.replace("\n", " ")
      |> String.replace(~r/\s{2,}/, " ")

    "data:image/svg+xml,#{encoded}"
  end

  defp selector_block(%Selector{selector: selectors, properties: properties}, namespace) do
    declarations =
      Enum.map(properties || [], fn %Property{name: name, value: value} ->
        "#{name}: #{CSS.resolve_pattern(value, namespace)};"
      end)

    wrap_block(Enum.join(selectors, ", "), declarations)
  end

  defp var_line({suffix, value}, namespace), do: "--#{namespace}-#{suffix}: #{value};"

  defp wrap_block(_header, []), do: nil

  defp wrap_block(header, lines) do
    body = lines |> Enum.join("\n") |> indent(2)
    "#{header} {\n#{body}\n}"
  end

  defp indent(text, n) do
    pad = String.duplicate(" ", n)

    text
    |> String.split("\n")
    |> Enum.map_join("\n", fn
      "" -> ""
      line -> pad <> line
    end)
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(_), do: false
end
