if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Resource.Transformers.MergeFormActions do
    @moduledoc false
    use Spark.Dsl.Transformer
    alias Spark.Dsl.Transformer
    alias Spark.Error.DslError
    alias Pyro.Resource.Form

    @ash_resource_transformers Ash.Resource.Dsl.transformers()

    @impl true
    def after?(module) when module in @ash_resource_transformers, do: true
    @impl true
    def after?(_), do: false

    @impl true
    def transform(dsl) do
      form_entities = Transformer.get_entities(dsl, [:pyro, :form])

      # convert to a map for fast access later
      actions =
        dsl
        |> Transformer.get_entities([:actions])
        |> Enum.reduce(%{}, &Map.put(&2, &1.name, &1))

      excluded_form_action_names =
        Transformer.get_option(dsl, [:pyro, :form], :exclude)

      # determine the actions that need form definitions
      expected_action_names =
        actions
        |> Map.values()
        |> Enum.filter(&(!Enum.any?(excluded_form_action_names, &1)))
        |> Enum.filter(&(&1.type in [:create, :update]))
        # TODO: Perhaps detect special forms of :destroy types that take arguments?
        |> Enum.map(& &1.name)

      %{form_actions: form_actions} =
        form_entities
        |> Enum.reduce(
          %{
            form_actions: [],
            form_types: %{},
            to_find: expected_action_names,
            exclusions: excluded_form_action_names,
            actions: actions
          },
          fn
            %Form.ActionType{name: names} = type, acc when is_list(names) ->
              fields = merge_fields(type.fields)

              Enum.reduce(names, acc, fn name, acc ->
                merge_action_type(
                  acc,
                  type
                  |> Map.put(:name, name)
                  |> Map.put(:fields, fields)
                )
              end)

            %Form.ActionType{} = type, acc ->
              fields = merge_fields(type.fields)
              merge_action_type(acc, Map.put(type, :fields, fields))

            %Form.Action{name: names} = action, acc when is_list(names) ->
              fields = merge_fields(action.fields)

              Enum.reduce(names, acc, fn name, acc ->
                merge_action(
                  acc,
                  action
                  |> Map.put(:name, name)
                  |> Map.put(:fields, fields)
                )
              end)

            %Form.Action{} = action, acc ->
              fields = merge_fields(action.fields)
              merge_action(acc, Map.put(action, :fields, fields))

            _, acc ->
              acc
          end
        )
        |> merge_defaults_from_types()

      # truncate all Action/ActionType entities because they will be unrolled/defaulted
      dsl =
        Transformer.remove_entity(dsl, [:pyro, :form], fn
          %Form.ActionType{} -> true
          %Form.Action{} -> true
          _ -> false
        end)

      dsl =
        Enum.reduce(form_actions, dsl, fn form_action, dsl ->
          Transformer.add_entity(dsl, [:pyro, :form], form_action, prepend: true)
        end)

      {:ok, dsl}
    end

    defp merge_action_type(_, %{name: name}) when name not in [:create, :update, :destroy] do
      raise(
        DslError.exception(
          path: [:pyro, :form, :action_type],
          message: """
          unsupported action type: #{name}
          """
        )
      )
    end

    defp merge_action_type(%{form_types: %{create: _}}, %{name: :create}) do
      raise(
        DslError.exception(
          path: [:pyro, :form, :action_type],
          message: """
          action type :create has already been defined
          """
        )
      )
    end

    defp merge_action_type(%{form_types: %{update: _}}, %{name: :update}) do
      raise(
        DslError.exception(
          path: [:pyro, :form, :action_type],
          message: """
          action type :update has already been defined
          """
        )
      )
    end

    defp merge_action_type(%{form_types: %{destroy: _}}, %{name: :destroy}) do
      raise(
        DslError.exception(
          path: [:pyro, :form, :action_type],
          message: """
          action type :destroy has already been defined
          """
        )
      )
    end

    defp merge_action_type(%{form_types: types} = acc, %{name: name} = type) do
      types = Map.put(types, name, type)
      Map.put(acc, :form_types, types)
    end

    defp merge_action(acc, %{name: name} = form_action) do
      action =
        acc.actions
        |> validate_action(name)
        |> validate_action_type()

      if name in acc.exclusions,
        do:
          raise(
            DslError.exception(
              path: [:pyro, :form, :action],
              message: """
              action #{name} is listed in `exclude`
              """
            )
          )

      form_action =
        form_action
        |> Map.put(:label, form_action.label || default_label(name))
        |> Map.put(:description, form_action.description || Map.get(action, :description))

      form_actions = [form_action | acc.form_actions]
      to_find = Enum.filter(acc.to_find, &(&1 == name))

      acc
      |> Map.put(:form_actions, form_actions)
      |> Map.put(:to_find, to_find)
    end

    defp validate_action(actions, name) do
      action = Map.get(actions, name)

      if action == nil,
        do:
          raise(
            DslError.exception(
              path: [:pyro, :form, :action],
              message: """
              action #{name} not found in resource
              """
            )
          )

      action
    end

    defp validate_action_type(%{name: name, type: type})
         when type not in [:create, :update, :destroy] do
      raise(
        DslError.exception(
          path: [:pyro, :form, :action],
          message: """
          action #{name} is an unsupported type: #{type}
          """
        )
      )
    end

    defp validate_action_type(action), do: action

    defp merge_defaults_from_types(%{to_find: []} = acc), do: acc

    defp merge_defaults_from_types(acc) do
      Enum.reduce(acc.to_find, acc, fn name, acc ->
        action =
          acc.actions
          |> validate_action(name)
          |> validate_action_type()

        type_default = Map.get(acc.form_types, action.type)

        if type_default == nil,
          do:
            raise(
              DslError.exception(
                path: [:pyro, :form],
                message: """

                Problem: Neither action #{name} nor defaults for type #{action.type} are defined.

                Solutions:
                  1. Add the action #{name} to the `exclude` list if a form is unneeded
                  2. Define the action #{name}
                  3. Define an action type default for type #{action.type}
                """
              )
            )

        merge_action(acc, %Form.Action{
          name: name,
          class: type_default.class,
          fields: type_default.fields
        })
      end)
    end

    defp merge_fields(fields, path \\ []) do
      Enum.map(fields, fn
        %Form.Field{} = field ->
          field
          |> Map.put(:label, field.label || default_label(field))
          |> Map.put(:path, maybe_append_path(path, field.path))

        %Form.FieldGroup{name: name} = group ->
          path = maybe_append_path(path, group.path)

          group
          |> Map.put(:label, group.label || default_label(group))
          |> Map.put(:path, path)
          |> Map.put(:fields, merge_fields(group.fields, path ++ [name]))
      end)
    end

    defp maybe_append_path(root, nil), do: root
    defp maybe_append_path(root, []), do: root
    defp maybe_append_path(root, path), do: root ++ List.wrap(path)

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
