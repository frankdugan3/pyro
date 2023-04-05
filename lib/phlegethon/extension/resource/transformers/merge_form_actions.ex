if Code.ensure_loaded?(Ash) do
  defmodule Phlegethon.Resource.Transformers.MergeFormActions do
    @moduledoc false
    use Spark.Dsl.Transformer
    alias Spark.Dsl.Transformer
    alias Phlegethon.Resource.Form

    @ash_resource_transformers Ash.Resource.Dsl.transformers()

    @impl true
    def after?(module) when module in @ash_resource_transformers, do: true
    @impl true
    def after?(_), do: false

    @impl true
    def transform(dsl) do
      form_entities = Transformer.get_entities(dsl, [:phlegethon, :form])

      resource = Transformer.get_persisted(dsl, :module)

      action_type_defaults = %{
        create: merge_action_types(form_entities, :create, dsl),
        update: merge_action_types(form_entities, :update, dsl),
        destroy: merge_action_types(form_entities, :destroy, dsl)
      }

      action_names =
        Enum.reduce(form_entities, [], fn
          %Form.Action{name: names}, acc when is_list(names) ->
            acc ++ names

          %Form.Action{name: name}, acc ->
            [name | acc]

          _, acc ->
            acc
        end)
        |> Enum.dedup()
        |> Enum.sort()

      dsl =
        Enum.reduce(form_entities, dsl, fn
          %Form.ActionType{name: name}, dsl ->
            Transformer.remove_entity(
              dsl,
              [:phlegethon, :form],
              &(&1.name == name)
            )

          %Form.Action{name: name}, dsl ->
            Transformer.remove_entity(
              dsl,
              [:phlegethon, :form],
              &(&1.name == name)
            )

          _, dsl ->
            dsl
        end)

      dsl =
        Enum.reduce(action_names, dsl, fn name, dsl ->
          action =
            dsl
            |> Transformer.get_entities([:actions])
            |> Enum.find(&(&1.name == name))

          if action == nil,
            do: raise("Action \"#{name}\" not found for resource #{resource} in UI form config!")

          type_defaults = Map.get(action_type_defaults, action.type)

          form_action =
            Enum.reduce(
              form_entities,
              %Form.Action{
                name: name,
                class: type_defaults.class,
                label: default_label(name),
                fields: type_defaults.fields
              },
              fn
                %Form.Action{name: names} = action, action_acc
                when is_list(names) ->
                  if name in names do
                    merge_action(action_acc, action, dsl)
                  else
                    action_acc
                  end

                %Form.Action{name: this_name} = action, action_acc
                when this_name == name ->
                  merge_action(action_acc, action, dsl)

                _, action_acc ->
                  action_acc
              end
            )

          Transformer.add_entity(dsl, [:phlegethon, :form], form_action)
        end)

      {:ok, dsl}
    end

    defp merge_action(old, new, dsl) do
      old
      |> maybe_override(new, :label)
      |> maybe_override(new, :class)
      |> merge_fields(new, dsl)
    end

    defp merge_action_types(_, type, _) when type not in [:create, :update, :destroy],
      do: raise("Invalid action_type \"#{type}\"!")

    defp merge_action_types(entities, type, dsl) do
      default_class = Form.ActionType.default_class()

      Enum.reduce(
        entities,
        %Form.ActionType{name: type, class: default_class, fields: []},
        fn
          %Form.ActionType{name: names} = action_type, acc
          when is_list(names) ->
            if type in names do
              acc
              |> maybe_override(action_type, :class)
              |> merge_fields(action_type, dsl)
            else
              acc
            end

          %Form.ActionType{name: name} = action_type, acc
          when name == type ->
            acc
            |> maybe_override(action_type, :class)
            |> merge_fields(action_type, dsl)

          _, acc ->
            acc
        end
      )
    end

    defp maybe_override(old, new, :class),
      do: Map.put(old, :class, Tails.classes([old.class, new.class]))

    defp maybe_override(old, new, :input_class),
      do: Map.put(old, :input_class, Tails.classes([old.class, new.class]))

    defp maybe_override(%{name: name, label: nil} = old, new, :label),
      do: maybe_override(Map.put(old, :label, default_label(name)), new, :label)

    defp maybe_override(old, new, key) do
      case Map.get(new, key) do
        nil -> old
        value -> Map.put(old, key, value)
      end
    end

    defp merge_fields(old, new, dsl) do
      {field_keys, field_values} =
        Enum.concat(old.fields, new.fields)
        |> Enum.reduce({[], %{}}, fn
          %Form.Field{name: name} = field, {keys, field_values} ->
            key = {Form.Field, name}

            case Map.get(field_values, key) do
              nil -> {[key | keys], Map.put(field_values, key, merge_field(field, field))}
              old_field -> {keys, Map.put(field_values, key, merge_field(old_field, field))}
            end

          %Form.FieldGroup{name: name} = field, {keys, field_values} ->
            key = {Form.FieldGroup, name}

            case Map.get(field_values, key) do
              nil ->
                {[key | keys], Map.put(field_values, key, merge_field_group(field, field, dsl))}

              old_field ->
                {keys, Map.put(field_values, key, merge_field_group(old_field, field, dsl))}
            end
        end)

      fields =
        field_keys
        |> Enum.reverse()
        |> Enum.map(fn
          key ->
            field = Map.get(field_values, key)
            group_path = Map.get(old, :path) || []
            path = Map.get(field, :path) || []
            Map.put(field, :path, group_path ++ path)
        end)

      Map.put(old, :fields, fields)
    end

    defp merge_field_group(old, new, dsl),
      do:
        old
        |> maybe_override(new, :label)
        |> maybe_override(new, :class)
        |> maybe_override(new, :path)
        |> merge_fields(new, dsl)

    defp merge_field(old, new),
      do:
        old
        |> maybe_override(new, :label)
        |> maybe_override(new, :type)
        |> maybe_override(new, :label)
        |> maybe_override(new, :description)
        |> maybe_override(new, :path)
        |> maybe_override(new, :class)
        |> maybe_override(new, :input_class)
        |> maybe_override(new, :autofocus)
        |> maybe_override(new, :prompt)
        |> maybe_override(new, :autocomplete_search_action)
        |> maybe_override(new, :autocomplete_search_arg)
        |> maybe_override(new, :autocomplete_option_label_key)
        |> maybe_override(new, :autocomplete_option_value_keu)

    defp default_label(%{name: name}), do: default_label(name)

    defp default_label(name) when is_atom(name),
      do: default_label(Atom.to_string(name))

    defp default_label(name) when is_binary(name),
      do:
        name
        |> String.split("_")
        |> Enum.map_join(" ", &String.capitalize/1)
  end
end
