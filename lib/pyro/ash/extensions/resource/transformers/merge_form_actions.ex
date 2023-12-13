if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Transformers.MergeFormActions do
    @moduledoc false

    use Pyro.Ash.Extensions.Resource.Transformers
    alias Pyro.Ash.Extensions.Resource.Form

    @ash_resource_transformers Ash.Resource.Dsl.transformers()

    @impl true
    def after?(module) when module in @ash_resource_transformers, do: true
    @impl true
    def after?(_), do: false

    @impl true
    def transform(dsl) do
      case Transformer.get_entities(dsl, [:pyro, :form]) do
        [] ->
          {:ok, dsl}

        form_entities ->
          # convert to a map for fast access later
          actions =
            dsl
            |> Transformer.get_entities([:actions])
            |> Enum.reduce(%{}, &Map.put(&2, &1.name, &1))

          excluded_form_action_names =
            Transformer.get_option(dsl, [:pyro, :form], :exclude, [])

          # determine the actions that need form definitions
          expected_action_names =
            actions
            |> Map.values()
            |> Enum.filter(fn action ->
              action.name not in excluded_form_action_names &&
                action.type in [:create, :update]
            end)
            # TODO: Perhaps detect special forms of :destroy types that take arguments?
            |> Enum.map(& &1.name)

          %{form_actions: form_actions, errors: errors} =
            form_entities
            |> Enum.reduce(
              %{
                form_actions: [],
                form_types: %{},
                to_find: expected_action_names,
                exclusions: excluded_form_action_names,
                actions: actions,
                errors: []
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

          handle_errors(errors, "form", dsl)
      end
    end

    defp merge_action_type(%{errors: errors} = acc, %{name: name})
         when name not in [:create, :update, :destroy] do
      errors = [
        DslError.exception(
          path: [:pyro, :form, :action_type],
          message: """
          unsupported action type: #{name}
          """
        )
        | errors
      ]

      Map.put(acc, :errors, errors)
    end

    defp merge_action_type(%{form_types: %{create: _}, errors: errors} = acc, %{name: :create}) do
      errors = [
        DslError.exception(
          path: [:pyro, :form, :action_type],
          message: """
          action type :create has already been defined
          """
        )
        | errors
      ]

      Map.put(acc, :errors, errors)
    end

    defp merge_action_type(%{form_types: %{update: _}, errors: errors} = acc, %{name: :update}) do
      errors = [
        DslError.exception(
          path: [:pyro, :form, :action_type],
          message: """
          action type :update has already been defined
          """
        )
        | errors
      ]

      Map.put(acc, :errors, errors)
    end

    defp merge_action_type(%{form_types: %{destroy: _}, errors: errors} = acc, %{name: :destroy}) do
      errors = [
        DslError.exception(
          path: [:pyro, :form, :action_type],
          message: """
          action type :destroy has already been defined
          """
        )
        | errors
      ]

      Map.put(acc, :errors, errors)
    end

    defp merge_action_type(%{form_types: types} = acc, %{name: name} = type) do
      types = Map.put(types, name, type)
      Map.put(acc, :form_types, types)
    end

    defp merge_action(%{errors: errors} = acc, %{name: name} = form_action) do
      case validate_action_and_type(acc.actions, name) do
        {:error, error} ->
          errors = [error | errors]
          Map.put(acc, :errors, errors)

        {:ok, action} ->
          if name in acc.exclusions do
            errors = [
              DslError.exception(
                path: [:pyro, :form, :action],
                message: """
                action #{name} is listed in `exclude`
                """
              )
              | errors
            ]

            Map.put(acc, :errors, errors)
          else
            form_action =
              form_action
              |> Map.put(:label, form_action.label || default_label(name))
              |> Map.put(:description, form_action.description || Map.get(action, :description))

            form_actions = [form_action | acc.form_actions]
            to_find = Enum.reject(acc.to_find, &(&1 == name))

            acc
            |> Map.put(:form_actions, form_actions)
            |> Map.put(:to_find, to_find)
          end
      end
    end

    defp validate_action_and_type(actions, name) do
      action = Map.get(actions, name)

      case action do
        nil ->
          {:error,
           DslError.exception(
             path: [:pyro, :form, :action],
             message: """
             action #{name} not found in resource
             """
           )}

        %{type: type} when type not in [:create, :update, :destroy] ->
          {:error,
           DslError.exception(
             path: [:pyro, :form, :action],
             message: """
             action #{name} is an unsupported type: #{type}
             """
           )}

        action ->
          {:ok, action}
      end
    end

    defp merge_defaults_from_types(%{to_find: []} = acc), do: acc

    defp merge_defaults_from_types(acc) do
      Enum.reduce(acc.to_find, acc, fn name, acc ->
        case validate_action_and_type(acc.actions, name) do
          {:error, error} ->
            errors = [error | acc.errors]
            Map.put(acc, :errors, errors)

          {:ok, action} ->
            type_default = Map.get(acc.form_types, action.type)

            if type_default == nil do
              errors = [
                DslError.exception(
                  path: [:pyro, :form],
                  message: """
                  form for action #{name} is not defined, has no type defaults, and is not excluded
                  """
                )
                | acc.errors
              ]

              Map.put(acc, :errors, errors)
            else
              merge_action(
                acc,
                %Form.Action{name: name}
                |> Map.merge(Map.drop(type_default, [:__struct__, :name]))
              )
            end
        end
      end)
    end

    defp merge_fields(fields, path \\ []) do
      Enum.map(fields, fn
        %Form.Field{} = field ->
          field
          |> Map.put(:label, field.label || default_label(field))
          |> Map.put(:path, maybe_append_path(path, field.path))

        %Form.FieldGroup{} = group ->
          path = maybe_append_path(path, group.path)

          group
          |> Map.put(:label, group.label || default_label(group))
          |> Map.put(:path, path)
          |> Map.put(:fields, merge_fields(group.fields, path))
      end)
    end

    defp maybe_append_path(root, nil), do: root
    defp maybe_append_path(root, []), do: root
    defp maybe_append_path(root, path), do: root ++ List.wrap(path)
  end
end
