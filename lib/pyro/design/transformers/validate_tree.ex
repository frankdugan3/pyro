defmodule Pyro.Design.Transformers.ValidateTree do
  @moduledoc false
  #
  # Runs the rules in the plan's validation table that can't be
  # enforced at entity-build time:
  #
  #   * names — no `$`, `.`, `{`, `}`
  #   * no case-only duplicate siblings
  #   * exactly-one of `:value` / `:ref` per token
  #   * `$type` resolvable via group-ancestry inheritance
  #   * `$type` ∈ the 13 DTCG types
  #   * `$root` rules (group-only, ≤1 per group, reserved name)
  #   * `$ref`/`$extends` — local-path target must exist
  #
  # Scalar/composite value shapes and colorSpace whitelist enforcement
  # already happened at macro-expansion time (via `Pyro.Design.Value`)
  # — this pass doesn't re-parse values.

  use Spark.Dsl.Transformer

  alias Pyro.Design.{Context, Group, Modifier, Reference, Token}
  alias Spark.Dsl.Transformer
  alias Spark.Error.DslError

  @dtcg_types Token.types()
  @bad_name_chars ["$", ".", "{", "}"]

  @impl true
  def transform(dsl) do
    module = Transformer.get_persisted(dsl, :module)
    children = Transformer.get_entities(dsl, [:design])
    allow_external_refs? = Transformer.get_persisted(dsl, :allow_external_refs?, false)

    {token_paths, group_paths, modifier_paths, context_paths} = index_tree(children, [])

    errors =
      []
      |> validate_names(children, [])
      |> validate_siblings(children, [])
      |> validate_tokens(token_paths, group_paths, allow_external_refs?)
      |> validate_groups(group_paths)
      |> validate_modifiers(modifier_paths, context_paths)

    case errors do
      [] ->
        {:ok, dsl}

      errors ->
        message =
          errors
          |> Enum.reverse()
          |> Enum.map_join("\n  * ", & &1)

        raise DslError,
          module: module,
          path: [:design],
          message: "Design DSL validation failed:\n  * #{message}"
    end
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

        %Modifier{name: name, contexts: ctx_list, default: default_ctx} ->
          modifier_path = prefix ++ [name]
          modifiers = Map.put(modifiers, modifier_path, entity)

          {sub_t, sub_g, sub_c} =
            index_contexts(ctx_list || [], modifier_path, default_ctx, prefix)

          {Map.merge(tokens, sub_t), Map.merge(groups, sub_g), modifiers,
           Map.merge(contexts, sub_c)}
      end
    end)
  end

  # Contexts carry the same child vocabulary as groups (tokens + groups);
  # modifiers can't nest inside a context per DTCG. Default-context
  # children also alias to the modifier's parent prefix so refs like
  # `$color.brand.500` resolve when the canonical declaration lives
  # inside `context :light` of a `default :light` modifier.
  defp index_contexts(context_list, modifier_path, default_ctx_name, unqualified_prefix) do
    Enum.reduce(context_list, {%{}, %{}, %{}}, fn %Context{name: name, children: children},
                                                  {tokens, groups, contexts} ->
      context_path = modifier_path ++ [name]
      contexts = Map.put(contexts, context_path, %Context{name: name})
      {sub_t, sub_g, _, _} = index_tree(children || [], context_path)

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

  defp validate_names(errors, entities, prefix) do
    Enum.reduce(entities, errors, fn entity, errors ->
      errors
      |> check_name_chars(entity, prefix)
      |> recurse_names(entity, prefix)
    end)
  end

  defp check_name_chars(errors, entity, prefix) do
    name_str = Atom.to_string(entity.name)

    if String.contains?(name_str, @bad_name_chars) and not entity_is_root?(entity) do
      [
        "name #{inspect(entity.name)} at path #{inspect(prefix)} contains a forbidden character — DTCG names must not contain #{inspect(@bad_name_chars)}"
        | errors
      ]
    else
      errors
    end
  end

  defp recurse_names(errors, %Group{name: name, children: children}, prefix),
    do: validate_names(errors, children || [], prefix ++ [name])

  defp recurse_names(errors, %Modifier{name: name, contexts: contexts}, prefix) do
    Enum.reduce(contexts || [], errors, fn %Context{} = ctx, err ->
      validate_names(err, [ctx], prefix ++ [name])
    end)
  end

  defp recurse_names(errors, %Context{name: name, children: children}, prefix),
    do: validate_names(errors, children || [], prefix ++ [name])

  defp recurse_names(errors, _entity, _prefix), do: errors

  defp entity_is_root?(%Token{root?: true, name: :"$root"}), do: true
  defp entity_is_root?(_), do: false

  defp validate_siblings(errors, entities, prefix) do
    names = Enum.map(entities, & &1.name)

    errors =
      names
      |> Enum.group_by(&String.downcase(Atom.to_string(&1)))
      |> Enum.reduce(errors, fn
        {_lower, [_single]}, errors ->
          errors

        {lower, dupes}, errors ->
          unique_raw = Enum.uniq(dupes)

          if length(unique_raw) == 1 do
            [
              "duplicate sibling name #{inspect(hd(unique_raw))} at path #{inspect(prefix)}"
              | errors
            ]
          else
            [
              "names #{inspect(unique_raw)} differ only by case (#{inspect(lower)}) at path #{inspect(prefix)}"
              | errors
            ]
          end
      end)

    Enum.reduce(entities, errors, fn
      %Group{name: name, children: children}, errors ->
        validate_siblings(errors, children || [], prefix ++ [name])

      %Modifier{name: name, contexts: contexts}, errors ->
        # Sibling names among contexts inside this modifier.
        errors = validate_siblings(errors, contexts || [], prefix ++ [name])

        # And recurse into each context's own children.
        Enum.reduce(contexts || [], errors, fn %Context{name: cname, children: cchildren}, err ->
          validate_siblings(err, cchildren || [], prefix ++ [name, cname])
        end)

      _, errors ->
        errors
    end)
  end

  defp validate_tokens(errors, token_paths, group_paths, allow_external_refs?) do
    Enum.reduce(token_paths, errors, fn {path, token}, errors ->
      errors
      |> check_value_xor_ref(path, token)
      |> check_type_resolvable(path, token, group_paths)
      |> check_ref_target(path, token, token_paths, group_paths, allow_external_refs?)
      |> check_root(path, token, group_paths)
    end)
  end

  defp check_value_xor_ref(errors, path, %Token{value: nil, ref: nil}),
    do: ["token at #{fmt(path)} must set either :value or :ref" | errors]

  defp check_value_xor_ref(errors, path, %Token{value: v, ref: r}) when v != nil and r != nil,
    do: ["token at #{fmt(path)} must not set both :value and :ref" | errors]

  defp check_value_xor_ref(errors, _path, _token), do: errors

  defp check_type_resolvable(errors, _path, %Token{ref: %Reference{}}, _group_paths), do: errors

  defp check_type_resolvable(errors, _path, %Token{type: type}, _group_paths)
       when type in @dtcg_types,
       do: errors

  defp check_type_resolvable(errors, path, %Token{type: nil}, group_paths) do
    if inherit_type(path, group_paths) do
      errors
    else
      ["token at #{fmt(path)} has no $type — set inline or on an ancestor group" | errors]
    end
  end

  defp check_type_resolvable(errors, path, %Token{type: bad}, _group_paths) do
    [
      "token at #{fmt(path)} has unknown $type #{inspect(bad)} — allowed: #{inspect(@dtcg_types)}"
      | errors
    ]
  end

  defp inherit_type(path, group_paths) do
    path
    |> ancestor_paths()
    |> Enum.reverse()
    |> Enum.find_value(fn ancestor ->
      case Map.get(group_paths, ancestor) do
        %Group{type: type} when type != nil -> type
        _ -> nil
      end
    end)
  end

  # Ancestor paths of a token path, deepest to shallowest.
  # [:a, :b, :c, :token] -> [[:a, :b, :c], [:a, :b], [:a]]
  defp ancestor_paths(path) do
    path
    |> Enum.drop(-1)
    |> do_ancestors([])
  end

  defp do_ancestors([], acc), do: acc
  defp do_ancestors(list, acc), do: do_ancestors(Enum.drop(list, -1), [list | acc])

  defp check_ref_target(
         errors,
         path,
         %Token{ref: %Reference{pointer: pointer} = ref},
         token_paths,
         group_paths,
         allow_external_refs?
       ) do
    cond do
      Map.has_key?(token_paths, pointer) or Map.has_key?(group_paths, pointer) ->
        errors

      allow_external_refs? ->
        errors

      true ->
        [
          "token at #{fmt(path)} has $ref #{inspect(Reference.to_string(ref))} that does not resolve to a local token or group"
          | errors
        ]
    end
  end

  defp check_ref_target(errors, _path, _token, _token_paths, _group_paths, _allow), do: errors

  defp check_root(errors, path, %Token{root?: true} = token, group_paths) do
    errors =
      if token.name == :"$root" do
        errors
      else
        [
          "token at #{fmt(path)} has root?: true but name #{inspect(token.name)} — `$root` token must be named :\"$root\""
          | errors
        ]
      end

    parent = Enum.drop(path, -1)

    if parent == [] do
      ["$root token only valid inside a group — found at top-level path #{fmt(path)}" | errors]
    else
      case Map.get(group_paths, parent) do
        %Group{} -> errors
        _ -> ["$root token at #{fmt(path)} has no parent group" | errors]
      end
    end
  end

  defp check_root(errors, _path, _token, _group_paths), do: errors

  defp validate_groups(errors, group_paths) do
    errors
    |> validate_at_most_one_root(group_paths)
    |> validate_extends_target(group_paths)
  end

  defp validate_at_most_one_root(errors, group_paths) do
    Enum.reduce(group_paths, errors, fn {path, %Group{children: children}}, errors ->
      roots = Enum.count(children || [], &match?(%Token{root?: true}, &1))

      if roots > 1 do
        ["group at #{fmt(path)} has #{roots} `$root` tokens — at most one allowed" | errors]
      else
        errors
      end
    end)
  end

  defp validate_extends_target(errors, group_paths) do
    Enum.reduce(group_paths, errors, &check_extends(&1, &2, group_paths))
  end

  defp check_extends({_path, %{extends: nil}}, errors, _group_paths), do: errors

  defp check_extends({path, %{extends: %Reference{pointer: pointer} = ref}}, errors, group_paths) do
    if Map.has_key?(group_paths, pointer) do
      errors
    else
      [
        "group at #{fmt(path)} has $extends #{inspect(Reference.to_string(ref))} that does not resolve to a local group"
        | errors
      ]
    end
  end

  defp validate_modifiers(errors, modifier_paths, context_paths) do
    Enum.reduce(modifier_paths, errors, fn {path, modifier}, errors ->
      errors
      |> check_min_contexts(path, modifier)
      |> check_default_context(path, modifier, context_paths)
    end)
  end

  defp check_min_contexts(errors, path, %Modifier{contexts: contexts}) do
    count = length(contexts || [])

    if count >= 2 do
      errors
    else
      [
        "modifier at #{fmt(path)} has #{count} context#{if count == 1, do: "", else: "s"} — DTCG requires at least 2"
        | errors
      ]
    end
  end

  defp check_default_context(errors, _path, %Modifier{default: nil}, _context_paths), do: errors

  defp check_default_context(errors, path, %Modifier{default: default}, context_paths) do
    expected_context_path = path ++ [default]

    if Map.has_key?(context_paths, expected_context_path) do
      errors
    else
      [
        "modifier at #{fmt(path)} declares default context #{inspect(default)} but no such context is defined"
        | errors
      ]
    end
  end

  defp fmt(path) do
    "[" <> Enum.map_join(path, ".", &Atom.to_string/1) <> "]"
  end
end
