defmodule Pyro.Design.Transformers.BuildTokenTree do
  @moduledoc false
  #
  # Persists the artifacts `Pyro.Design.Info` and downstream consumers
  # read at runtime:
  #
  #   * `:design_tree`          — a synthetic root %Group{children: entities}
  #   * `:design_token_paths`   — %{[atom()] => %Token{}}
  #   * `:design_group_paths`   — %{[atom()] => %Group{}}
  #   * `:design_modifier_paths`— %{[atom()] => %Modifier{}}
  #   * `:design_context_paths` — %{[atom()] => %Context{}}
  #   * `:design_type_map`      — %{[atom()] => dtcg_type_atom} (with inheritance)
  #   * `:design_refs`          — %{from_path => %Reference{}}  (tokens' $ref + groups' $extends)
  #   * `:design_icon_map`      — %{atom() => svg_string}

  use Spark.Dsl.Transformer

  alias Pyro.Design.{Context, Group, Icon, Modifier, Reference, Token}
  alias Spark.Dsl.Transformer

  @impl true
  def after?(Pyro.Design.Transformers.ValidateTree), do: true
  def after?(_), do: false

  @impl true
  def transform(dsl) do
    children = Transformer.get_entities(dsl, [:design])
    icons = Transformer.get_entities(dsl, [:icons])

    root = %Group{
      name: :__root__,
      type: nil,
      description: nil,
      deprecated: false,
      extends: nil,
      extensions: %{},
      children: children
    }

    {token_paths, group_paths, modifier_paths, context_paths} = index_tree(children, [])
    type_map = resolve_type_map(token_paths, group_paths)
    refs = collect_refs(token_paths, group_paths)
    icon_map = Map.new(icons, fn %Icon{name: name, svg: svg} -> {name, svg} end)

    dsl =
      dsl
      |> Transformer.persist(:design_tree, root)
      |> Transformer.persist(:design_token_paths, token_paths)
      |> Transformer.persist(:design_group_paths, group_paths)
      |> Transformer.persist(:design_modifier_paths, modifier_paths)
      |> Transformer.persist(:design_context_paths, context_paths)
      |> Transformer.persist(:design_type_map, type_map)
      |> Transformer.persist(:design_refs, refs)
      |> Transformer.persist(:design_icon_map, icon_map)

    {:ok, dsl}
  end

  defp index_tree(entities, prefix) do
    Enum.reduce(entities, {%{}, %{}, %{}, %{}}, fn entity,
                                                   {tokens, groups, modifiers, contexts} ->
      case entity do
        %Token{name: name} ->
          {Map.put(tokens, prefix ++ [name], entity), groups, modifiers, contexts}

        %Group{name: name, children: children} ->
          path = prefix ++ [name]
          groups = Map.put(groups, path, entity)
          {sub_t, sub_g, sub_m, sub_c} = index_tree(children || [], path)

          {Map.merge(tokens, sub_t), Map.merge(groups, sub_g), Map.merge(modifiers, sub_m),
           Map.merge(contexts, sub_c)}

        %Modifier{name: name, contexts: ctx_list, default: default_ctx} = modifier ->
          path = prefix ++ [name]
          modifiers = Map.put(modifiers, path, modifier)
          {sub_t, sub_g, sub_c} = index_contexts(ctx_list || [], path, default_ctx, prefix)

          {Map.merge(tokens, sub_t), Map.merge(groups, sub_g), modifiers,
           Map.merge(contexts, sub_c)}
      end
    end)
  end

  defp index_contexts(context_list, modifier_path, default_ctx_name, unqualified_prefix) do
    Enum.reduce(context_list, {%{}, %{}, %{}}, fn %Context{name: name, children: children} = ctx,
                                                  {tokens, groups, contexts} ->
      context_path = modifier_path ++ [name]
      contexts = Map.put(contexts, context_path, ctx)
      {sub_t, sub_g, _, _} = index_tree(children || [], context_path)

      # The default context's children are also reachable at the
      # unqualified path (as if declared at the modifier's parent
      # scope). Lets refs like `$color.brand.500` resolve when the
      # canonical declaration lives inside `context :light` of a
      # `default :light` modifier, rather than forcing top-level
      # duplication.
      {extra_t, extra_g} =
        if not is_nil(default_ctx_name) and name == default_ctx_name do
          {ut, ug, _, _} = index_tree(children || [], unqualified_prefix)
          {ut, ug}
        else
          {%{}, %{}}
        end

      {tokens |> Map.merge(sub_t) |> Map.merge(extra_t),
       groups |> Map.merge(sub_g) |> Map.merge(extra_g), contexts}
    end)
  end

  # Walks each token path, finds its type (either inline or inherited from
  # nearest ancestor group that sets :type).
  defp resolve_type_map(token_paths, group_paths) do
    Map.new(token_paths, fn {path, %Token{} = token} ->
      type =
        cond do
          token.type != nil -> token.type
          token.ref != nil -> nil
          true -> inherit_type(path, group_paths)
        end

      {path, type}
    end)
  end

  defp inherit_type(path, group_paths) do
    path
    |> Enum.drop(-1)
    |> ancestors_deepest_first()
    |> Enum.find_value(fn ancestor ->
      case Map.get(group_paths, ancestor) do
        %Group{type: type} when type != nil -> type
        _ -> nil
      end
    end)
  end

  defp ancestors_deepest_first(list) do
    do_ancestors(list, [])
  end

  defp do_ancestors([], acc), do: Enum.reverse(acc)
  defp do_ancestors(list, acc), do: do_ancestors(Enum.drop(list, -1), [list | acc])

  defp collect_refs(token_paths, group_paths) do
    token_refs =
      for {path, %Token{ref: %Reference{} = ref}} <- token_paths, into: %{} do
        {path, ref}
      end

    group_refs =
      for {path, %Group{extends: %Reference{} = ref}} <- group_paths, into: %{} do
        {path, ref}
      end

    Map.merge(token_refs, group_refs)
  end
end
