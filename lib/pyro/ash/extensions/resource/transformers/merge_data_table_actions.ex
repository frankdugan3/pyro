if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Transformers.MergeDataTableActions do
    @moduledoc false

    use Pyro.Ash.Extensions.Resource.Transformers

    alias Pyro.Ash.Extensions.Resource.DataTable

    @ash_resource_transformers Ash.Resource.Dsl.transformers()

    @impl true
    def after?(module) when module in @ash_resource_transformers, do: true
    @impl true
    def after?(_), do: false

    @impl true
    def transform(dsl) do
      case Transformer.get_entities(dsl, [:pyro, :data_table]) do
        [] ->
          {:ok, dsl}

        data_table_entities ->
          excluded_data_table_action_names =
            Transformer.get_option(dsl, [:pyro, :data_table], :exclude, [])

          # truncate all Action/ActionType entities because they will be unrolled/defaulted
          dsl =
            Transformer.remove_entity(dsl, [:pyro, :data_table], fn
              %DataTable.ActionType{} -> true
              %DataTable.Action{} -> true
              _ -> false
            end)

          # determine the actions that need data table definitions
          expected_action_names =
            dsl
            |> filter_actions(fn action ->
              action.name not in excluded_data_table_action_names &&
                action.type in [:read]
            end)
            |> Enum.map(& &1.name)

          %{data_table_actions: data_table_actions, errors: errors} =
            data_table_entities
            |> Enum.reduce(
              %{
                dsl: dsl,
                data_table_actions: [],
                data_table_types: %{},
                to_find: expected_action_names,
                exclusions: excluded_data_table_action_names,
                errors: []
              },
              &reduce_data_table_entities/2
            )
            |> merge_defaults_from_types()

          dsl =
            Enum.reduce(data_table_actions, dsl, fn data_table_action, dsl ->
              Transformer.add_entity(dsl, [:pyro, :data_table], data_table_action, prepend: true)
            end)

          handle_errors(errors, "data table", dsl)
      end
    end

    defp reduce_data_table_entities(%DataTable.ActionType{name: names} = type, acc) when is_list(names) do
      columns = merge_columns(type.columns)

      Enum.reduce(names, acc, fn name, acc ->
        merge_action_type(
          acc,
          type
          |> Map.put(:name, name)
          |> Map.put(:columns, columns)
        )
      end)
    end

    defp reduce_data_table_entities(%DataTable.ActionType{} = type, acc) do
      columns = merge_columns(type.columns)
      merge_action_type(acc, Map.put(type, :columns, columns))
    end

    defp reduce_data_table_entities(%DataTable.Action{name: names} = action, acc) when is_list(names) do
      columns = merge_columns(action.columns)

      Enum.reduce(names, acc, fn name, acc ->
        merge_action(
          acc,
          action
          |> Map.put(:name, name)
          |> Map.put(:columns, columns)
        )
      end)
    end

    defp reduce_data_table_entities(%DataTable.Action{} = action, acc) do
      columns = merge_columns(action.columns)
      merge_action(acc, Map.put(action, :columns, columns))
    end

    defp reduce_data_table_entities(_, acc) do
      acc
    end

    defp merge_action_type(%{errors: errors} = acc, %{name: name}) when name not in [:read] do
      errors = [
        DslError.exception(
          path: [:pyro, :data_table, :action_type],
          message: """
          unsupported action type: #{name}
          """
        )
        | errors
      ]

      Map.put(acc, :errors, errors)
    end

    defp merge_action_type(%{data_table_types: %{read: _}, errors: errors} = acc, %{name: :read}) do
      errors = [
        DslError.exception(
          path: [:pyro, :data_table, :action_type],
          message: """
          action type :read has already been defined
          """
        )
        | errors
      ]

      Map.put(acc, :errors, errors)
    end

    defp merge_action_type(%{data_table_types: types} = acc, %{name: name} = type) do
      types = Map.put(types, name, type)
      Map.put(acc, :data_table_types, types)
    end

    defp merge_action(%{errors: errors} = acc, %{name: name} = data_table_action) do
      case validate_action_and_type(acc.dsl, name) do
        {:error, error} ->
          errors = [error | errors]
          Map.put(acc, :errors, errors)

        {:ok, action} ->
          if name in acc.exclusions do
            errors = [
              DslError.exception(
                path: [:pyro, :data_table, :action],
                message: """
                action #{name} is listed in `exclude`
                """
              )
              | errors
            ]

            Map.put(acc, :errors, errors)
          else
            data_table_action =
              data_table_action
              |> Map.put(:label, data_table_action.label || default_label(name))
              |> Map.put(
                :description,
                data_table_action.description || Map.get(action, :description)
              )

            data_table_actions = [data_table_action | acc.data_table_actions]
            to_find = Enum.reject(acc.to_find, &(&1 == name))

            acc
            |> Map.put(:data_table_actions, data_table_actions)
            |> Map.put(:to_find, to_find)
          end
      end
    end

    defp validate_action_and_type(dsl, name) do
      action = get_action(dsl, name)

      case action do
        nil ->
          {:error,
           DslError.exception(
             path: [:pyro, :data_table, :action],
             message: """
             action #{name} does not exist on this resource
             """
           )}

        %{type: type} when type not in [:read] ->
          {:error,
           DslError.exception(
             path: [:pyro, :data_table, :action],
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
        case validate_action_and_type(acc.dsl, name) do
          {:error, error} ->
            errors = [error | acc.errors]
            Map.put(acc, :errors, errors)

          {:ok, action} ->
            type_default = Map.get(acc.data_table_types, action.type)

            if type_default == nil do
              errors = [
                DslError.exception(
                  path: [:pyro, :data_table],
                  message: """
                  data table for action #{name} is not defined, has no type defaults, and is not excluded
                  """
                )
                | acc.errors
              ]

              Map.put(acc, :errors, errors)
            else
              merge_action(
                acc,
                Map.merge(%DataTable.Action{name: name}, Map.drop(type_default, [:__struct__, :name]))
              )
            end
        end
      end)
    end

    defp merge_columns(columns, path \\ []) do
      Enum.map(columns, fn
        %DataTable.Column{} = column ->
          column
          |> Map.put(:label, column.label || default_label(column))
          |> Map.put(:path, maybe_append_path(path, column.path))
      end)
    end

    defp maybe_append_path(root, nil), do: root
    defp maybe_append_path(root, []), do: root
    defp maybe_append_path(root, path), do: root ++ List.wrap(path)
  end
end
