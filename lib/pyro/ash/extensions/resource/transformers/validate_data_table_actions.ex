if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Verifiers.DataTableActions do
    @moduledoc false

    use Pyro.Ash.Extensions.Resource.Verifiers

    alias Pyro.Ash.Extensions.Resource.DataTable
    alias Spark.Dsl.Extension

    @impl true
    def verify(dsl_state) do
      data_table_actions = Verifier.get_entities(dsl_state, [:pyro, :data_table])

      []
      |> check_actions(data_table_actions, dsl_state)
      |> check_actions_for_duplicate_labels(data_table_actions)
      |> handle_errors("data table")
    end

    defp check_actions(errors, data_table_actions, dsl_state) do
      Enum.reduce(data_table_actions, errors, fn action, errors ->
        check_action(errors, action, dsl_state)
      end)
    end

    defp check_action(errors, %DataTable.Action{} = action, dsl_state) do
      resource = Extension.get_persisted(dsl_state, :module)

      public_fields =
        dsl_state
        |> Ash.Resource.Info.public_fields()
        |> MapSet.new(& &1.name)

      private_fields =
        dsl_state
        |> Ash.Resource.Info.fields()
        |> Enum.filter(& &1.private?)
        |> MapSet.new(& &1.name)

      errors
      |> check_action_for_duplicate_path_names(action)
      |> check_action_for_duplicate_path_labels(action)
      |> check_action_for_public_field_inclusion(action, public_fields)
      |> validate_action_default_sort(action, resource)
      |> validate_action_default_display(action)
      |> validate_action_columns(action, public_fields, private_fields)
    end

    defp check_action_for_duplicate_path_names(errors, %DataTable.Action{columns: columns, name: action_name}) do
      columns
      |> Enum.group_by(fn %{path: path, name: name} ->
        path
        |> Kernel.++([name])
        |> Enum.join(".")
      end)
      |> Enum.reduce(errors, fn {name, groups}, errors ->
        name_count = Enum.count(groups)

        if name_count == 1 do
          errors
        else
          [
            DslError.exception(
              path: [:pyro, :data_table, :action, action_name, name],
              message: "action #{inspect(action_name)}, #{name_count} columns duplicate the path/name #{inspect(name)}"
            )
            | errors
          ]
        end
      end)
    end

    defp check_action_for_duplicate_path_labels(errors, %DataTable.Action{columns: columns, name: action_name}) do
      columns
      |> Enum.group_by(fn %{path: path, label: label} ->
        path
        |> Kernel.++([label])
        |> Enum.join(".")
      end)
      |> Enum.reduce(errors, fn {label, groups}, errors ->
        label_count = Enum.count(groups)

        if label_count == 1 do
          errors
        else
          [
            DslError.exception(
              path: [:pyro, :data_table, :action, action_name, label],
              message: "action #{inspect(action_name)}, #{label_count} columns duplicate the path/label #{inspect(label)}"
            )
            | errors
          ]
        end
      end)
    end

    defp check_action_for_public_field_inclusion(
           errors,
           %DataTable.Action{columns: columns, name: action_name, exclude: exclude},
           public_fields
         ) do
      public_fields
      |> Enum.filter(&(&1 not in exclude))
      |> Enum.reduce(errors, fn name, errors ->
        if Enum.find(columns, &(&1.path == [] && &1.name == name)) do
          errors
        else
          [
            DslError.exception(
              path: [:pyro, :data_table, :action, action_name],
              message: "action #{inspect(action_name)}, attribute #{inspect(name)} not in columns"
            )
            | errors
          ]
        end
      end)
    end

    defp validate_action_default_sort(
           errors,
           %DataTable.Action{
             columns: columns,
             name: action_name,
             default_sort: default_sort,
             default_display: default_display
           },
           resource
         ) do
      case Ash.Sort.parse_input(resource, default_sort) do
        {:ok, nil} ->
          errors

        {:ok, sort} when is_list(sort) ->
          sort_fields = Keyword.keys(sort)

          Enum.reduce(sort_fields, errors, fn field, errors ->
            errors =
              if Enum.find(columns, &(&1.name == field)) do
                errors
              else
                [
                  DslError.exception(
                    path: [:pyro, :data_table, :action, action_name, :default_sort],
                    message: "action #{inspect(action_name)}, sort field #{inspect(field)} not in columns"
                  )
                  | errors
                ]
              end

            if Enum.find(default_display, &(&1 == field)) do
              errors
            else
              [
                DslError.exception(
                  path: [:pyro, :data_table, :action, action_name, :default_display],
                  message: "action #{inspect(action_name)}, sort field #{inspect(field)} not in default display"
                )
                | errors
              ]
            end
          end)

        {:error, error} ->
          [
            DslError.exception(
              path: [:pyro, :data_table, :action, action_name, :default_sort],
              message: Ash.ErrorKind.message(error)
            )
            | errors
          ]
      end
    end

    defp validate_action_default_display(errors, %DataTable.Action{
           columns: columns,
           name: action_name,
           default_display: default_display
         }) do
      Enum.reduce(default_display, errors, fn field, errors ->
        if Enum.find(columns, &(&1.name == field)) do
          errors
        else
          [
            DslError.exception(
              path: [
                :pyro,
                :data_table,
                :action,
                action_name,
                :default_display
              ],
              message: "action #{inspect(action_name)}, display field #{inspect(field)} not in columns"
            )
            | errors
          ]
        end
      end)
    end

    defp validate_action_columns(
           errors,
           %DataTable.Action{columns: columns, name: action_name},
           public_fields,
           private_fields
         ) do
      Enum.reduce(columns, errors, fn
        %{name: column_name, path: []}, errors ->
          cond do
            MapSet.member?(public_fields, column_name) ->
              errors

            MapSet.member?(private_fields, column_name) ->
              [
                DslError.exception(
                  path: [:pyro, :data_table, :action, action_name],
                  message: "action #{inspect(action_name)}, #{inspect(column_name)} is a private field"
                )
                | errors
              ]

            true ->
              [
                DslError.exception(
                  path: [:pyro, :data_table, :action, action_name],
                  message:
                    "action #{inspect(action_name)}, #{inspect(column_name)} is not an attribute, aggregate, calculation or relationship"
                )
                | errors
              ]
          end

        _, errors ->
          errors
      end)
    end

    defp check_actions_for_duplicate_labels(errors, []), do: errors

    defp check_actions_for_duplicate_labels(errors, data_table_actions) do
      data_table_actions
      |> Enum.group_by(& &1.label)
      |> Enum.reduce(errors, fn {label, groups}, acc ->
        label_count = Enum.count(groups)

        if label_count == 1 do
          acc
        else
          [
            DslError.exception(
              path: [:pyro, :data_table, :action],
              message: "#{label_count} actions share the label #{inspect(label)}"
            )
            | errors
          ]
        end
      end)
    end
  end
end
