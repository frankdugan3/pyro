defmodule Pyro.Design.Transformers.GenerateDocs do
  @moduledoc false
  #
  # Walks the DTCG tree and emits a markdown summary that is appended
  # to the design module's `@moduledoc` via `Pyro.Design.handle_before_compile`.
  # Kept deliberately minimal — per-type tables with token name, value,
  # and description.

  use Spark.Dsl.Transformer

  alias Pyro.Design.{Icon, Reference, Token}
  alias Spark.Dsl.Transformer

  @impl true
  def after?(Pyro.Design.Transformers.BuildTokenTree), do: true
  def after?(_), do: false

  @impl true
  def transform(dsl) do
    token_paths = Transformer.get_persisted(dsl, :design_token_paths, %{})
    type_map = Transformer.get_persisted(dsl, :design_type_map, %{})
    icons = Transformer.get_entities(dsl, [:icons])

    token_section = build_token_section(token_paths, type_map)
    icon_section = build_icon_section(icons)

    docs =
      [token_section, icon_section]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n\n")

    {:ok, Transformer.persist(dsl, :design_docs, docs)}
  end

  defp build_token_section(token_paths, type_map) do
    if map_size(token_paths) == 0 do
      nil
    else
      by_type =
        token_paths
        |> Enum.group_by(fn {path, _token} -> Map.get(type_map, path) end)
        |> Enum.sort_by(fn {type, _} -> type |> to_string() end)

      "## Tokens\n\n" <> Enum.map_join(by_type, "\n\n", &render_type_table/1)
    end
  end

  defp render_type_table({type, entries}) do
    rows =
      entries
      |> Enum.sort_by(fn {path, _} -> path end)
      |> Enum.map_join("\n", &render_token_row/1)

    "### #{type_heading(type)}\n\n| Path | Value | Description |\n| --- | --- | --- |\n" <> rows
  end

  defp render_token_row({path, token}) do
    "| `#{render_path(path)}` | #{render_value(token)} | #{token.description || ""} |"
  end

  defp build_icon_section([]), do: nil

  defp build_icon_section(icons) do
    rows =
      icons
      |> Enum.sort_by(& &1.name)
      |> Enum.map_join("\n", fn %Icon{name: name} -> "| `#{name}` |" end)

    "## Icons\n\n| Name |\n| --- |\n" <> rows
  end

  defp type_heading(nil), do: "Uncategorised"

  defp type_heading(type),
    do: type |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  defp render_path(path), do: Enum.map_join(path, ".", &Atom.to_string/1)

  defp render_value(%Token{ref: %Reference{} = ref}), do: "→ #{Reference.to_string(ref)}"
  defp render_value(%Token{value: nil}), do: "—"

  defp render_value(%Token{value: value}),
    do: "`#{inspect(value, limit: 3, printable_limit: 40)}`"
end
