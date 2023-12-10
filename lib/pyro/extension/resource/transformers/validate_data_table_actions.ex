if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Resource.Transformers.ValidateDataTableActions do
    @moduledoc false
    use Spark.Dsl.Transformer
    alias Spark.Dsl.Transformer
    alias Spark.Error.DslError
    alias Pyro.Resource.DataTable

    @impl true
    def after_compile?, do: true

    @impl true
    def transform(dsl_state) do
      {private_attributes, public_attributes} =
        dsl_state
        |> Transformer.get_entities([:attributes])
        |> Enum.split_with(& &1.private?)

      {private_aggregates, public_aggregates} =
        dsl_state
        |> Transformer.get_entities([:aggregates])
        |> Enum.split_with(& &1.private?)

      {private_calculations, public_calculations} =
        dsl_state
        |> Transformer.get_entities([:calculations])
        |> Enum.split_with(& &1.private?)

      {private_relationships, public_relationships} =
        dsl_state
        |> Transformer.get_entities([:relationships])
        |> Enum.split_with(& &1.private?)

      private_fields =
        Enum.concat([
          private_attributes,
          private_aggregates,
          private_calculations,
          private_relationships
        ])
        |> MapSet.new(& &1.name)

      public_fields =
        Enum.concat([
          public_attributes,
          public_aggregates,
          public_calculations,
          public_relationships
        ])
        |> MapSet.new(& &1.name)

      data_table_actions = Transformer.get_entities(dsl_state, [:pyro, :data_table])

      errors =
        Enum.reduce(
          data_table_actions,
          [],
          fn
            %DataTable.Action{name: action_name, columns: columns, exclude: exclude}, errors ->
              # No duplicate path-names
              errors =
                Enum.group_by(columns, fn %{path: path, name: name} ->
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
                        message:
                          "action #{inspect(action_name)}, #{name_count} columns duplicate the path/name #{inspect(name)}"
                      )
                      | errors
                    ]
                  end
                end)

              errors =
                Enum.group_by(columns, fn %{path: path, label: label} ->
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
                        message:
                          "action #{inspect(action_name)}, #{label_count} columns duplicate the path/label #{inspect(label)}"
                      )
                      | errors
                    ]
                  end
                end)

              errors =
                public_fields
                |> Enum.filter(&(&1 not in exclude))
                |> Enum.reduce(errors, fn name, errors ->
                  if Enum.find(columns, &(&1.path == [] && &1.name == name)) do
                    errors
                  else
                    [
                      DslError.exception(
                        path: [:pyro, :data_table, :action, action_name],
                        message:
                          "action #{inspect(action_name)}, attribute #{inspect(name)} not in data table columns"
                      )
                      | errors
                    ]
                  end
                end)

              Enum.reduce(columns, errors, fn
                %{name: column_name, path: []}, errors ->
                  cond do
                    MapSet.member?(public_fields, column_name) ->
                      errors

                    MapSet.member?(private_fields, column_name) ->
                      [
                        DslError.exception(
                          path: [:pyro, :data_table, :action, action_name],
                          message:
                            "action #{inspect(action_name)}, #{inspect(column_name)} is a private field"
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
        )

      errors =
        if Enum.empty?(data_table_actions) do
          errors
        else
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

      case errors do
        [] ->
          :ok

        [error] ->
          raise(error)

        errors ->
          list =
            errors
            |> Enum.reverse()
            |> Enum.map(&("   - " <> &1.message))
            |> Enum.dedup()
            |> Enum.join("\n")

          raise(
            DslError.exception(
              path: [:pyro, :data_table],
              message: """
              There are multiple errors with the data table:
              #{list}
              """
            )
          )
      end
    end
  end
end
