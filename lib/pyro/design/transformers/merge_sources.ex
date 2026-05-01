defmodule Pyro.Design.Transformers.MergeSources do
  @moduledoc false
  #
  # Merges each source in `use Pyro.Design, sources: [...]` into this
  # module's DSL state, **in declared order**. Per DTCG resolver
  # `resolutionOrder` semantics, later sources override earlier ones at
  # equal paths; this module's own declarations (from its `design do ... end`)
  # are applied last by nature of being in the DSL state when the
  # transformer runs.
  #
  # ## Source item shapes
  #
  #   * **module atom** — a compiled `Pyro.Design` module. Its
  #     persisted `:design` and `:icons` entities are deep-merged in.
  #   * **string** — a path to a DTCG JSON file. **Not yet implemented**
  #     — raises a `Spark.Error.DslError` pointing at module sources.
  #
  # ## Merge rules (deep, entity-level)
  #
  #   * Same-named `group`s are combined — parent's children come
  #     first, this module's children second. Recursion applies.
  #   * Same-named tokens / modifiers / per-type entities → this
  #     module's version wins ("last source wins per path").
  #   * Different-named entities from a source are added.
  #   * Icon map: child wins on name collision, otherwise parent's
  #     icons merge in.
  #
  # Also:
  #   * A source module's `:config` options (`namespace`,
  #     `tailwind_preamble`) fill in for any key not set locally.
  #   * `config > base_layer` entities (`selector`, `raw`) inherit
  #     wholesale from the source if the current design declares no
  #     base_layer entities of its own. If the child declares any,
  #     they replace the source's set entirely (no per-entity merge).
  #   * Persists `:design_sources_chain` — the transitive chain of
  #     module sources (root-to-leaf). Cycles error.
  #
  # Runs before `MergeDuplicateContexts` and `ValidateTree`.

  use Spark.Dsl.Transformer

  alias Pyro.Design.Group
  alias Spark.Dsl.Transformer
  alias Spark.Error.DslError

  @impl true
  def before?(Pyro.Design.Transformers.MergeDuplicateContexts), do: true
  def before?(Pyro.Design.Transformers.ValidateTree), do: true
  def before?(Pyro.Design.Transformers.BuildTokenTree), do: true
  def before?(_), do: false

  @impl true
  def transform(dsl) do
    sources = Transformer.get_persisted(dsl, :design_sources_raw, [])
    module = Transformer.get_persisted(dsl, :module)

    chain = build_chain(sources, module)

    dsl =
      Enum.reduce(chain, dsl, &merge_source/2)
      |> Transformer.persist(:design_sources_chain, chain)

    {:ok, dsl}
  end

  # Build the flat, transitive resolution order of all modules to merge,
  # root-to-leaf, from the declared `sources` list. Cycles raise.
  defp build_chain(sources, local) do
    Enum.flat_map(sources, fn
      source when is_atom(source) ->
        resolve_module_chain(source, [local], local)

      source when is_binary(source) ->
        raise DslError,
          module: local,
          path: [:design],
          message:
            "DTCG JSON source loading is not yet implemented; pass a `Pyro.Design` module instead (got: #{inspect(source)})"
    end)
  end

  defp resolve_module_chain(module, visited, local) do
    if module in visited do
      raise DslError,
        module: local,
        path: [:design],
        message:
          "cyclic `sources:` chain: " <>
            Enum.map_join(Enum.reverse([module | visited]), " -> ", &inspect/1)
    end

    grandparents =
      Spark.Dsl.Extension.get_persisted(module, :design_sources_chain, [])

    Enum.flat_map(grandparents, &resolve_module_chain(&1, [module | visited], local)) ++
      [module]
  end

  defp merge_source(source_module, dsl) do
    source_design = Spark.Dsl.Extension.get_entities(source_module, [:design]) || []
    source_icons = Spark.Dsl.Extension.get_entities(source_module, [:icons]) || []

    dsl
    |> merge_design(source_design)
    |> merge_icons(source_icons)
    |> inherit_base_layer(source_module)
    |> inherit_config(source_module)
  end

  defp merge_design(dsl, source_entities) do
    Map.update(dsl, [:design], %{entities: source_entities, opts: []}, fn config ->
      Map.update(config, :entities, source_entities, fn local ->
        deep_merge_entities(source_entities, local)
      end)
    end)
  end

  defp merge_icons(dsl, source_icons) do
    Map.update(dsl, [:icons], %{entities: source_icons, opts: []}, fn config ->
      Map.update(config, :entities, source_icons, fn local ->
        local_names = MapSet.new(local, & &1.name)
        source_only = Enum.reject(source_icons, &MapSet.member?(local_names, &1.name))
        source_only ++ local
      end)
    end)
  end

  # Deep-merge two sibling lists: same-named groups combine recursively,
  # other same-named entities let the child (local) entity win.
  defp deep_merge_entities(parent_list, child_list) do
    child_by_name = Map.new(child_list, &{&1.name, &1})

    merged_from_parent =
      Enum.map(parent_list, fn parent_entity ->
        case Map.fetch(child_by_name, parent_entity.name) do
          {:ok, child_entity} -> combine(parent_entity, child_entity)
          :error -> parent_entity
        end
      end)

    parent_names = MapSet.new(parent_list, & &1.name)
    child_only = Enum.reject(child_list, &MapSet.member?(parent_names, &1.name))

    (merged_from_parent ++ child_only) |> dedupe_by_name()
  end

  defp dedupe_by_name(list) do
    {_, out} =
      Enum.reduce(list, {MapSet.new(), []}, fn entity, {seen, acc} ->
        if MapSet.member?(seen, entity.name) do
          {seen, acc}
        else
          {MapSet.put(seen, entity.name), [entity | acc]}
        end
      end)

    Enum.reverse(out)
  end

  defp combine(%Group{children: parent_children}, %Group{children: child_children} = child) do
    %{child | children: deep_merge_entities(parent_children || [], child_children || [])}
  end

  defp combine(_parent, child), do: child

  # base_layer is inherited like a single config option: if the current
  # design declares any entities, they override the source entirely;
  # otherwise the source's entities fill in.
  defp inherit_base_layer(dsl, source_module) do
    case Transformer.get_entities(dsl, [:config, :base_layer]) do
      [] ->
        source_entities =
          Spark.Dsl.Extension.get_entities(source_module, [:config, :base_layer]) || []

        Map.update(
          dsl,
          [:config, :base_layer],
          %{entities: source_entities, opts: []},
          &Map.put(&1, :entities, source_entities)
        )

      _ ->
        dsl
    end
  end

  defp inherit_config(dsl, source_module) do
    Enum.reduce([:namespace, :tailwind_preamble], dsl, &inherit_config_key(&1, &2, source_module))
  end

  defp inherit_config_key(key, dsl, source_module) do
    case Transformer.fetch_option(dsl, [:config], key) do
      {:ok, _} -> dsl
      :error -> apply_source_config(dsl, key, source_module)
    end
  end

  defp apply_source_config(dsl, key, source_module) do
    case Spark.Dsl.Extension.get_opt(source_module, [:config], key) do
      nil -> dsl
      value -> Transformer.set_option(dsl, [:config], key, value)
    end
  end
end
