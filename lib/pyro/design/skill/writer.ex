defmodule Pyro.Design.Skill.Writer do
  @moduledoc false

  alias Pyro.Design.{Context, CSS, Group, Icon, Info, Modifier, Reference, Token}

  @skills_root ".claude/skills"

  @doc "Filenames (relative to the project's `.claude/skills/` root) the writer emits for the given design."
  @spec files(module()) :: [String.t()]
  def files(design_module) do
    dir = skill_dir(design_module)
    ["#{dir}/SKILL.md", "#{dir}/tokens.md", "#{dir}/modifiers.md", "#{dir}/icons.md"]
  end

  @doc "The `.claude/skills/` root the writer emits into."
  @spec root() :: String.t()
  def root, do: @skills_root

  def write(design_module) do
    if Info.generate_skills?(design_module) do
      design_dir = Path.join(@skills_root, skill_dir(design_module))
      File.rm_rf!(design_dir)

      design_module
      |> build()
      |> Enum.each(fn {rel, content} ->
        path = Path.join(@skills_root, rel)
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, content)
      end)
    end

    :ok
  end

  def build(design_module) do
    ctx = collect(design_module)
    dir = ctx.skill_dir

    %{
      "#{dir}/SKILL.md" => render_skill(ctx),
      "#{dir}/tokens.md" => render_tokens(ctx),
      "#{dir}/modifiers.md" => render_modifiers(ctx),
      "#{dir}/icons.md" => render_icons(ctx)
    }
  end

  defp skill_dir(design_module), do: "#{Info.namespace(design_module)}-design"

  defp collect(design) do
    %{
      design: design,
      module_name: inspect(design),
      namespace: Info.namespace(design),
      skill_dir: skill_dir(design),
      tokens: Info.tokens(design),
      type_map: Info.type_map(design),
      refs: Info.refs(design),
      modifiers: Info.modifiers(design),
      icons: Info.icons(design),
      source_path: source_path(design)
    }
  end

  defp source_path(design) do
    case design.__info__(:compile)[:source] do
      nil -> nil
      list when is_list(list) -> List.to_string(list)
      bin when is_binary(bin) -> bin
    end
  end

  defp render_skill(ctx) do
    source_line =
      case ctx.source_path do
        nil -> ""
        path -> "Source file: `#{relative_to_cwd(path)}`.\n\n"
      end

    """
    ---
    name: #{ctx.skill_dir}
    description: Use when writing a Phoenix component (HEEx) for the #{ctx.module_name} design, or when adding/changing tokens, modifiers, contexts, icons, or composition sources in that design. Covers colocated `<style>` blocks routed through `Pyro.LiveView.ColocatedCSS`, the `$token.path` reference syntax, modifier behaviour, icon usage, and the `Pyro.Design` DSL surface.
    ---

    # `#{ctx.module_name}` design system

    CSS namespace: `#{ctx.namespace}`. Every design lookup resolves to `var(--#{ctx.namespace}-<dashed-path>)` at runtime.

    Reference material lives alongside this skill: [tokens.md](./tokens.md), [modifiers.md](./modifiers.md), [icons.md](./icons.md).

    This skill covers two activities — pick the section that matches what you're doing.

    ---

    # Writing components

    ## Colocated CSS

    Define a wrapper once in your project:

        defmodule MyAppWeb.ColocatedCSS do
          use Pyro.LiveView.ColocatedCSS, design: #{ctx.module_name}
        end

    Then in any HEEx component:

        ~H\"\"\"
        <button class="btn">{@label}</button>
        <style :type={MyAppWeb.ColocatedCSS}>
          .btn {
            background: $color.brand.500;
            color: $color.bg;
            padding: $space.md;
          }
        </style>
        \"\"\"

    ### Rules the validator enforces at compile time

    - Use `$dotted.token.path`. The wrapper rewrites it to `var(--#{ctx.namespace}-<dashed-path>)`.
    - Inside `@media (...)` query conditions, `$path` resolves to the **literal** value, because `var()` is invalid in media queries.
    - Raw `var(--#{ctx.namespace}-…)` is rejected — always go through `$path` so the validator sees the lookup.
    - Unknown paths raise at compile of the calling component. Add the token to the design first (see "Customizing the design" below).

    ## Modifier-aware tokens

    Modifiers don't appear in token paths. The same `$path` resolves to a different value depending on which `data-<modifier>="<context>"` attribute is present on an ancestor — usually `<html>` or `<body>`. Modifier and context names are kebab-cased in the attribute (underscores in the source become dashes in CSS, matching every other Pyro CSS identifier).#{modifier_example_line(ctx)}

    See [modifiers.md](./modifiers.md) for every modifier and the tokens it re-binds.

    ## Icons

    **Prefer the project's icon component if one exists.** Most projects wrap the data-attribute pattern in a named component (e.g. `<.icon name="…" />`, `<MyAppWeb.Icon name="…" />`). Search the project before reaching for the raw selector — using the wrapper preserves whatever sizing, accessibility (`aria-hidden`, role), and class conventions the project already standardised on. Only fall back to the raw form when the user explicitly asks for it or no wrapper exists.

    Raw form:

        <span data-#{ctx.namespace}-icon="<name>" />

    The CSS writer emits `[data-#{ctx.namespace}-icon="<name>"]` rules with mask-image SVGs. Available icon names: see [icons.md](./icons.md).

    ## Token vocabulary

    The complete list of tokens with values and descriptions: [tokens.md](./tokens.md).

    When in doubt, prefer an existing semantic token (e.g. `color.bg`, `space.md`) over a deeper raw token (e.g. `color.brand.500`) — semantic tokens are the ones modifiers re-bind, so they'll respond to dark mode, density, etc.

    ## Anti-patterns

    - Hard-coded colours, sizes, durations, or shadows that duplicate a token. Reference the token instead.
    - Inventing token paths. They raise at compile. If a token is missing, add it (see below).

    ---

    # Customizing the design

    #{source_line}The design declares its full DTCG vocabulary inside a single module:

        use Pyro.Design

        design do
          group :color do
            color :bg, "#ffffff"

            group :brand do
              type :color
              color :"500", "oklch(0.55 0.18 250)"
            end
          end

          modifier :color_mode do
            default :light

            context :light do
              color :bg, "#ffffff"
            end

            context :dark do
              color :bg, "#0a0a0a"
            end
          end
        end

        icons do
          icon :chevron_down, ~SVG"<svg>…</svg>"
        end

        config do
          namespace "#{ctx.namespace}"
        end

    ## Common edits

    ### Add a token

    Pick the typed macro that matches your DTCG type — `color`, `dimension`, `duration`, `font_family`, `font_weight`, `cubic_bezier`, `number`, `stroke_style`, `border`, `transition`, `shadow`, `gradient`, `typography`. Place it inside the appropriate group, or at top level if it's standalone:

        group :color do
          color :surface, "#fafafa"
        end

    ### Add a group

    Groups nest freely. Set `type` once on the group to inherit it through descendants:

        group :radius do
          type :dimension
          dimension :sm, 0.25, :rem
          dimension :md, 0.5, :rem
        end

    ### Reference / alias another token

    Use `ref` at top level for cross-tree pointers, or `extends` inside a group to inherit every child of another group:

        ref :primary_action, "#/color/brand/500"

        group :button do
          extends "#/color/brand"
          color :pressed, "oklch(0.45 0.2 250)"
        end

    ### Add a modifier or context

    Modifiers re-bind tokens conditionally. Each context overrides the same paths declared at the design root:

        modifier :density do
          description "Compact vs comfortable spacing."
          default :comfortable

          context :comfortable do
            dimension :gap, 1.0, :rem
          end

          context :compact do
            dimension :gap, 0.5, :rem
          end
        end

    After adding the modifier, attach `data-density="compact"` to an ancestor element to flip every component using `$gap`.

    ### Add an icon

    `~SVG` compiles inline SVG into the form the CSS writer expects:

        icons do
          icon :star, ~SVG"<svg viewBox='0 0 24 24'><path d='…'/></svg>"
        end

    ### Compose another design

    Stack designs via `:sources` — later sources override earlier ones, and this module's own declarations are applied last (DTCG Resolver `resolutionOrder` semantics):

        use Pyro.Design, sources: [#{ctx.module_name}]

        design do
          color :bg, "#000000"
        end

    ## DSL surface reference

    - Top-level sections: `config`, `design`, `icons`.
    - `config` keys: `namespace` (required), `tailwind_preamble`, plus `base_layer` for app-level base CSS.
    - Output options on `use Pyro.Design`: `:json_output`, `:css_output`, `:generate_skills?`, `:support_tailwind?`, `:manage_base_layer?`.
    - Persisted introspection: `Pyro.Design.Info` exposes `tokens/1`, `type_map/1`, `refs/1`, `modifiers/1`, `contexts/1`, `icons/1`, `namespace/1`, plus the path-keyed accessors.

    ## Verifying changes

    After editing, recompile (`mix compile`) — the DSL transformers re-run and the JSON / CSS / skill outputs regenerate automatically. The compiled `@moduledoc` includes a token / icon table for quick visual diff against [tokens.md](./tokens.md).
    """
  end

  defp modifier_example_line(%{modifiers: m}) when map_size(m) == 0, do: ""

  defp modifier_example_line(%{modifiers: modifiers}) do
    {_path, %Modifier{name: name, contexts: contexts, default: default}} =
      Enum.min_by(modifiers, fn {p, _} -> p end)

    other_ctx = Enum.find(contexts, fn %Context{name: c} -> c != default end) || hd(contexts)
    " Example for this design: `<html data-#{dash(name)}=\"#{dash(other_ctx.name)}\">`."
  end

  defp render_tokens(ctx) do
    body =
      case typed_sections(ctx) do
        [] -> "_No tokens declared._"
        sections -> Enum.join(sections, "\n\n")
      end

    aliases = render_aliases_section(ctx)

    [
      "# `#{ctx.module_name}` — Token reference\n\n" <>
        "Namespace: `#{ctx.namespace}` — every token resolves to `var(--#{ctx.namespace}-<dashed-path>)`.",
      body,
      aliases
    ]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n\n")
    |> Kernel.<>("\n")
  end

  defp typed_sections(ctx) do
    modifier_paths = Map.keys(ctx.modifiers)

    by_type =
      ctx.tokens
      |> Enum.reject(fn {path, %Token{} = token} ->
        ref_only?(token, ctx.type_map[path]) or under_any?(path, modifier_paths)
      end)
      |> Enum.group_by(fn {path, %Token{type: type}} -> type || ctx.type_map[path] end)

    Token.types()
    |> Enum.flat_map(fn type ->
      case Map.get(by_type, type, []) do
        [] -> []
        rows -> [render_token_table(type, rows)]
      end
    end)
  end

  defp ref_only?(%Token{ref: %Reference{}}, _type), do: true
  defp ref_only?(%Token{}, _type), do: false

  defp under_any?(path, modifier_paths) do
    Enum.any?(modifier_paths, fn mod_path ->
      List.starts_with?(path, mod_path)
    end)
  end

  defp render_token_table(type, rows) do
    sorted = Enum.sort_by(rows, fn {path, _} -> path end)

    table_rows =
      sorted
      |> Enum.map_join("\n", fn {path, token} ->
        "| `#{render_path(path)}` | #{render_value(token)} | #{render_description(token)} |"
      end)

    "## #{type_heading(type)}\n\n| Path | Value | Description |\n| --- | --- | --- |\n" <> table_rows
  end

  defp render_aliases_section(ctx) do
    rows =
      ctx.refs
      |> Enum.sort_by(fn {path, _} -> path end)
      |> Enum.map_join("\n", fn {path, %Reference{pointer: pointer}} ->
        "| `#{render_path(path)}` | `#{render_path(pointer)}` |"
      end)

    if rows == "" do
      ""
    else
      "## Aliases\n\nPure references — they emit `var(--…)` pointing at the target, so updating the target updates every consumer.\n\n| Path | Target |\n| --- | --- |\n" <>
        rows
    end
  end

  defp render_modifiers(ctx) do
    intro =
      "# `#{ctx.module_name}` — Modifiers\n\nModifiers don't appear in token paths. They re-bind a subset of tokens conditionally — the same `$path` keeps working, but its computed value changes per context. Attach the modifier's `data-<modifier>=\"<context>\"` attribute to an ancestor element (commonly `<html>` or `<body>`) to switch contexts. Modifier and context names are kebab-cased in the attribute — `:color_mode` → `data-color-mode`."

    body =
      case Map.values(ctx.modifiers) do
        [] ->
          "_No modifiers declared._"

        list ->
          list
          |> Enum.sort_by(& &1.name)
          |> Enum.map_join("\n\n", &render_modifier_section(&1, ctx))
      end

    intro <> "\n\n" <> body <> "\n"
  end

  defp render_modifier_section(%Modifier{} = mod, _ctx) do
    header = "## `#{mod.name}`#{if mod.description, do: " — " <> mod.description, else: ""}"

    default_line =
      if mod.default do
        first_other =
          Enum.find(mod.contexts, fn %Context{name: c} -> c != mod.default end) ||
            hd(mod.contexts)

        "Default context: `#{mod.default}`. Toggle via `<html data-#{dash(mod.name)}=\"#{dash(first_other.name)}\">`."
      else
        ""
      end

    table = render_modifier_table(mod)

    [header, default_line, table]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n\n")
  end

  defp render_modifier_table(%Modifier{contexts: contexts}) do
    overrides_per_ctx =
      Enum.map(contexts, fn %Context{name: name, children: children} ->
        {name, flatten_overrides(children || [], [])}
      end)

    all_paths =
      overrides_per_ctx
      |> Enum.flat_map(fn {_, m} -> Map.keys(m) end)
      |> Enum.uniq()
      |> Enum.sort()

    body =
      case all_paths do
        [] -> "_No tokens re-bound._"
        paths -> render_modifier_rows(contexts, overrides_per_ctx, paths)
      end

    "Re-bound tokens:\n\n" <> body
  end

  defp render_modifier_rows(contexts, overrides_per_ctx, all_paths) do
    header =
      "| Token re-bound | " <>
        Enum.map_join(contexts, " | ", fn %Context{name: n} -> "`#{n}`" end) <> " |"

    sep = "| --- | " <> Enum.map_join(contexts, " | ", fn _ -> "---" end) <> " |"

    rows =
      Enum.map_join(all_paths, "\n", fn path ->
        cells = render_modifier_cells(overrides_per_ctx, path)
        "| `#{render_path(path)}` | #{cells} |"
      end)

    Enum.join([header, sep, rows], "\n")
  end

  defp render_modifier_cells(overrides_per_ctx, path) do
    Enum.map_join(overrides_per_ctx, " | ", fn {_ctx_name, overrides} ->
      case Map.fetch(overrides, path) do
        {:ok, %Token{} = token} -> render_value(token)
        :error -> ""
      end
    end)
  end

  defp flatten_overrides(nodes, prefix) do
    Enum.reduce(nodes, %{}, fn
      %Token{name: name} = token, acc ->
        Map.put(acc, prefix ++ [name], token)

      %Group{name: name, children: children}, acc ->
        Map.merge(acc, flatten_overrides(children || [], prefix ++ [name]))
    end)
  end

  defp render_icons(ctx) do
    intro = """
    # `#{ctx.module_name}` — Icons

    If the project ships an icon component (`<.icon name="…" />` or similar), use it — it almost certainly wraps this pattern with consistent sizing and accessibility. Only use the raw selector below when no wrapper exists or the user asks for it.

    ## Raw form

    Render an icon by setting the namespaced data attribute on any element:

        <span data-#{ctx.namespace}-icon="<name>" />

    The CSS writer emits `[data-#{ctx.namespace}-icon="<name>"]` rules with mask-image SVGs.

    ## Available icons
    """

    body =
      case ctx.icons do
        [] ->
          "_No icons declared._"

        icons ->
          icons
          |> Enum.sort_by(& &1.name)
          |> Enum.map_join("\n", fn %Icon{name: name} -> "- `#{name}`" end)
      end

    intro <> "\n" <> body <> "\n"
  end

  defp render_path(path), do: Enum.map_join(path, ".", &Atom.to_string/1)

  defp render_value(%Token{ref: %Reference{} = ref}), do: "→ `#{Reference.to_string(ref)}`"
  defp render_value(%Token{value: nil}), do: "—"
  defp render_value(%Token{value: value, type: :typography}), do: render_typography(value)
  defp render_value(%Token{value: value}), do: "`#{CSS.format_value(value)}`"

  defp render_typography(%{} = t) do
    parts =
      [
        t[:font_family] && family_to_string(t.font_family),
        t[:font_size] && CSS.format_value(t.font_size),
        t[:line_height] && "/ #{CSS.format_value(t.line_height)}",
        t[:font_weight] && "weight #{CSS.format_value(t.font_weight)}",
        t[:letter_spacing] && "tracking #{CSS.format_value(t.letter_spacing)}"
      ]
      |> Enum.reject(&is_nil/1)

    "`" <> Enum.join(parts, " ") <> "`"
  end

  defp family_to_string([first | _]), do: first
  defp family_to_string(other), do: CSS.format_value(other)

  defp render_description(%Token{description: nil, deprecated: false}), do: ""

  defp render_description(%Token{description: nil, deprecated: dep}),
    do: deprecated_suffix(dep)

  defp render_description(%Token{description: desc, deprecated: false}), do: desc

  defp render_description(%Token{description: desc, deprecated: dep}),
    do: desc <> " " <> deprecated_suffix(dep)

  defp deprecated_suffix(true), do: "_(deprecated)_"
  defp deprecated_suffix(reason) when is_binary(reason), do: "_(deprecated: #{reason})_"
  defp deprecated_suffix(_), do: ""

  defp type_heading(nil), do: "Uncategorised"

  defp type_heading(type),
    do: type |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  defp dash(name) when is_atom(name), do: name |> Atom.to_string() |> String.replace("_", "-")
  defp dash(name) when is_binary(name), do: String.replace(name, "_", "-")

  defp relative_to_cwd(path) do
    cwd = File.cwd!()

    case Path.relative_to(path, cwd) do
      ^path -> path
      rel -> rel
    end
  end
end
