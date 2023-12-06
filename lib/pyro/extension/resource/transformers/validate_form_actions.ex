if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Resource.Transformers.ValidateFormActions do
    @moduledoc false
    use Spark.Dsl.Transformer
    alias Spark.Dsl.Transformer
    alias Spark.Error.DslError
    alias Pyro.Resource.Form

    @impl true
    def after_compile?, do: true

    @impl true
    def transform(dsl_state) do
      {private_attributes, public_attributes} =
        dsl_state
        |> Transformer.get_entities([:attributes])
        |> Enum.split_with(& &1.private?)

      {writable_attributes, unwritable_attributes} =
        Enum.split_with(public_attributes, & &1.writable?)

      writable_attribute_names = MapSet.new(writable_attributes, & &1.name)
      private_attribute_names = MapSet.new(private_attributes, & &1.name)
      unwritable_attribute_names = MapSet.new(unwritable_attributes, & &1.name)

      form_actions = Transformer.get_entities(dsl_state, [:pyro, :form])
      actions = Transformer.get_entities(dsl_state, [:actions])

      errors =
        Enum.reduce(
          form_actions,
          [],
          fn
            %Form.Action{name: action_name, fields: fields}, errors ->
              all = flatten_fields(fields)

              # No duplicate path-names
              errors =
                Enum.group_by(all, fn %{path: path, name: name} ->
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
                        path: [:pyro, :form, :action, action_name, name],
                        message:
                          "#{name_count} field/field_groups duplicate the path/name #{name}"
                      )
                      | errors
                    ]
                  end
                end)

              errors =
                Enum.group_by(all, fn %{path: path, label: label} ->
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
                        path: [:pyro, :form, :action, action_name, label],
                        message:
                          "#{label_count} field/field_groups duplicate the path/label #{label}"
                      )
                      | errors
                    ]
                  end
                end)

              case Enum.find(actions, &(&1.name == action_name)) do
                nil ->
                  [
                    DslError.exception(
                      path: [:pyro, :form, :action, action_name],
                      message: "action #{action_name} does not exist on this resource"
                    )
                    | errors
                  ]

                %{type: type} when type not in [:create, :update, :delete] ->
                  [
                    DslError.exception(
                      path: [:pyro, :form, :action, action_name],
                      message: "action #{action_name} is an unsupported type: #{type}"
                    )
                    | errors
                  ]

                action ->
                  all_fields = Enum.filter(all, &(&1.__struct__ == Form.Field))

                  errors =
                    case Enum.count(all_fields, &(&1.autofocus == true)) do
                      0 ->
                        [
                          DslError.exception(
                            path: [:pyro, :form, :action, action_name],
                            message: "exactly one field must have autofocus"
                          )
                          | errors
                        ]

                      1 ->
                        errors

                      count ->
                        [
                          DslError.exception(
                            path: [:pyro, :form, :action, action_name],
                            message:
                              "#{count} autofocus fields; exactly one field must have autofocus"
                          )
                          | errors
                        ]
                    end

                  errors =
                    action.accept
                    |> Enum.filter(&(&1 in writable_attribute_names))
                    |> Enum.reduce(errors, fn name, errors ->
                      if Enum.find(all_fields, &(&1.path == [] && &1.name == name)) do
                        errors
                      else
                        dbg(all_fields)
                        dbg(name)

                        [
                          DslError.exception(
                            path: [:pyro, :form, :action, action_name],
                            message: "action #{action_name}: attribute #{name} not in form fields"
                          )
                          | errors
                        ]
                      end
                    end)

                  Enum.reduce(all_fields, errors, fn
                    %{name: field_name, path: []}, errors ->
                      matching_argument =
                        Enum.find(action.arguments, &(&1.name == field_name))

                      cond do
                        field_name not in action.accept && !matching_argument ->
                          [
                            DslError.exception(
                              path: [:pyro, :form, :action, action_name],
                              message:
                                "action #{action_name}: #{field_name} is not an accepted attribute or argument"
                            )
                            | errors
                          ]

                        MapSet.member?(writable_attribute_names, field_name) ->
                          errors

                        # TODO: Validate arguments
                        !!matching_argument ->
                          errors

                        # Check these after argument validation, or will get false positives on private attributes
                        MapSet.member?(private_attribute_names, field_name) ->
                          [
                            DslError.exception(
                              path: [:pyro, :form, :action, action_name],
                              message:
                                "action #{action_name}: #{field_name} is a private attribute"
                            )
                            | errors
                          ]

                        MapSet.member?(unwritable_attribute_names, field_name) ->
                          [
                            DslError.exception(
                              path: [:pyro, :form, :action, action_name],
                              message:
                                "action #{action_name}: #{field_name} is an unwritable attribute"
                            )
                            | errors
                          ]

                        true ->
                          [
                            DslError.exception(
                              path: [:pyro, :form, :action, action_name],
                              message: "action #{action_name}: #{field_name} is not an attribute"
                            )
                            | errors
                          ]
                      end

                    _, errors ->
                      errors
                  end)
              end
          end
        )

      errors =
        if Enum.empty?(form_actions) do
          errors
        else
          form_actions
          |> Enum.group_by(& &1.label)
          |> Enum.reduce(errors, fn {label, groups}, acc ->
            label_count = Enum.count(groups)

            if label_count == 1 do
              acc
            else
              [
                DslError.exception(
                  path: [:pyro, :form, :action],
                  message: "#{label_count} actions share the label #{label}"
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
              path: [:pyro, :form],
              message: """
              There are multiple errors with the form:
              #{list}
              """
            )
          )
      end
    end

    defp flatten_fields(fields),
      do:
        fields
        |> Enum.reduce([], fn
          %Form.FieldGroup{fields: fields} = field_group, acc ->
            Enum.concat(flatten_fields(fields), [%{field_group | fields: []} | acc])

          field, acc ->
            [field | acc]
        end)
  end
end
