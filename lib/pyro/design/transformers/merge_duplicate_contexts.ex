defmodule Pyro.Design.Transformers.MergeDuplicateContexts do
  @moduledoc false
  #
  # Walks the `:design` tree and, for every modifier encountered,
  # collapses same-named sibling contexts by concatenating their
  # `:children` lists. DTCG resolver modifiers map context names to a
  # single set of sources; authors may legitimately split a context's
  # declarations across multiple `context :name do ... end` blocks
  # (for organization, conditional compilation, etc.) that need to be
  # merged before ValidateTree runs (which would otherwise flag
  # duplicate sibling names).

  use Spark.Dsl.Transformer

  alias Pyro.Design.{Context, Group, Modifier}
  alias Spark.Dsl.Transformer

  @impl true
  def before?(Pyro.Design.Transformers.ValidateTree), do: true
  def before?(Pyro.Design.Transformers.BuildTokenTree), do: true
  def before?(_), do: false

  @impl true
  def transform(dsl) do
    entities = Transformer.get_entities(dsl, [:design])
    updated = Enum.map(entities, &walk/1)

    dsl =
      Map.update(dsl, [:design], %{entities: updated, opts: []}, fn config ->
        %{config | entities: updated}
      end)

    {:ok, dsl}
  end

  defp walk(%Group{children: children} = group),
    do: %{group | children: Enum.map(children || [], &walk/1)}

  defp walk(%Modifier{contexts: contexts} = modifier),
    do: %{modifier | contexts: merge_same_named(contexts || [])}

  defp walk(other), do: other

  defp merge_same_named(contexts) do
    {_seen, merged} =
      Enum.reduce(contexts, {%{}, []}, fn %Context{name: name} = ctx, {seen, acc} ->
        case Map.fetch(seen, name) do
          :error ->
            {Map.put(seen, name, length(acc)), acc ++ [ctx]}

          {:ok, index} ->
            %Context{} = existing = Enum.at(acc, index)

            merged_ctx = %{
              existing
              | children: (existing.children || []) ++ (ctx.children || [])
            }

            {seen, List.replace_at(acc, index, merged_ctx)}
        end
      end)

    merged
  end
end
