if Code.ensure_loaded?(Ash) do
  defmodule Phlegethon.Resource.Transformers.ValidateFormActions do
    @moduledoc false
    use Spark.Dsl.Transformer
    alias Spark.Dsl.Transformer
    alias Spark.Error.DslError
    alias Phlegethon.Resource.Form

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

      form_actions = Transformer.get_entities(dsl_state, [:phlegethon, :form])

      write_actions =
        Transformer.get_entities(dsl_state, [:actions]) |> Enum.filter(&(&1.type != :read))

      Enum.each(
        form_actions,
        fn
          %Form.Action{name: action_name, fields: fields} ->
            all = flatten_fields(fields)

            # No duplicate path-names
            Enum.group_by(all, fn %{path: path, name: name} ->
              path
              |> Kernel.++([name])
              |> Enum.join(".")
            end)
            |> Enum.each(fn {name, groups} ->
              name_count = Enum.count(groups)

              unless name_count == 1 do
                raise DslError.exception(
                        path: [:phlegethon, :form, :action, action_name, name],
                        message: """
                        There are #{name_count} field/field_groups that share the path/name `#{name}`. A given path/name should only be defined once per action. Ensure you are not duplicating fields and that you are not using field_group names that match a field name.
                        """
                      )
              end
            end)

            # No duplicate path/labels
            Enum.group_by(all, fn %{path: path, label: label} ->
              path
              |> Kernel.++([label])
              |> Enum.join(".")
            end)
            |> Enum.each(fn {label, groups} ->
              label_count = Enum.count(groups)

              unless label_count == 1 do
                raise DslError.exception(
                        path: [:phlegethon, :form, :action, action_name, label],
                        message: """
                        There are #{label_count} field/field_groups that share the path/label `#{label}`. This will make it impossible for an end-user to distinguish the field/groups for this action. A given path/label should only be defined once per action. Ensure you are not duplicating fields and that you are not using field_group labels that match a field label.
                        """
                      )
              end
            end)

            action = Enum.find(write_actions, &(&1.name == action_name))

            # Action exists
            unless action do
              raise DslError.exception(
                      path: [:phlegethon, :form, :action, action_name],
                      message: """
                      The `phlegethon` form is referring to action `#{action_name}`, but it does not exist on this resource.
                      """
                    )
            end

            all_fields = Enum.filter(all, &(&1.__struct__ == Form.Field))

            # Autofocus properly specified
            case Enum.count(all_fields, &(&1.autofocus == true)) do
              0 ->
                raise DslError.exception(
                        path: [:phlegethon, :form, :action, action_name],
                        message: """
                        There are no fields that have `autofocus true`. The form won't know what field to focus on mount.
                        """
                      )

              1 ->
                :ok

              count ->
                raise DslError.exception(
                        path: [:phlegethon, :form, :action, action_name],
                        message: """
                        There are #{count} fields that have `autofocus true`. Only one field can be auto-focused.
                        """
                      )
            end

            # All writable accepted attributes are in form.
            action.accept
            |> Enum.filter(&(&1 in writable_attribute_names))
            |> Enum.each(fn name ->
              unless Enum.find(all_fields, &(&1.path == [] && &1.name == name)) do
                raise DslError.exception(
                        path: [:phlegethon, :form, :action, action_name],
                        message: """
                        The action `#{action_name}` has the attribute `#{name}` accepted and writable, but no matching field entry exists in the form definition.
                        """
                      )
              end
            end)

            all_fields
            |> Enum.each(fn %{name: field_name, path: []} ->
              matching_argument = Enum.find(action.arguments, &(&1.name == field_name))

              cond do
                field_name not in action.accept && !matching_argument ->
                  raise DslError,
                    path: [:phlegethon, :form, :action, action_name],
                    message: "#{field_name} is not an accepted attribute or argument"

                MapSet.member?(writable_attribute_names, field_name) ->
                  :ok

                # TODO: Validate arguments
                !!matching_argument ->
                  :ok

                # Check these after argument validation, or will get false positives on private attributes
                MapSet.member?(private_attribute_names, field_name) ->
                  raise DslError,
                    path: [:phlegethon, :form, :action, action_name],
                    message: "#{field_name} is a private attribute"

                MapSet.member?(unwritable_attribute_names, field_name) ->
                  raise DslError,
                    path: [:phlegethon, :form, :action, action_name],
                    message: "#{field_name} is an unwritable attribute"

                true ->
                  raise DslError,
                    path: [:phlegethon, :form, :action, action_name],
                    message: "#{field_name} is not an attribute"
              end
            end)

            :ok
        end
      )

      form_action_names = MapSet.new(form_actions, & &1.name)

      # Only validate if form is configured
      # TODO: Require form to be disabled by option, use that instead of length (because we want to explicitly disable forms rather than implicitly)
      unless Enum.empty?(form_actions) do
        # No duplicate actions
        form_actions
        |> Enum.group_by(& &1.name)
        |> Enum.each(fn {name, groups} ->
          name_count = Enum.count(groups)

          unless name_count == 1 do
            raise DslError.exception(
                    path: [:phlegethon, :form, :action],
                    message: """
                    There are #{name_count} actions that share the name `#{name}`. This is likely a `phlegethon` extension bug since action config should be merged.
                    """
                  )
          end
        end)

        form_actions
        |> Enum.group_by(& &1.label)
        |> Enum.each(fn {label, groups} ->
          label_count = Enum.count(groups)

          unless label_count == 1 do
            raise DslError.exception(
                    path: [:phlegethon, :form, :action],
                    message: """
                    There are #{label_count} actions that share the label `#{label}`. This will make it impossible for an end-user to distinguish the actions for this resource.
                    """
                  )
          end
        end)

        # All write actions have forms
        # TODO: Consider different checks -- do we want forms for destroy? If so, require explicit exclusions.
        write_actions
        |> Enum.filter(&(&1.type != :destroy))
        |> Enum.each(fn %{name: name} ->
          if MapSet.member?(form_action_names, name) do
            :ok
          else
            raise DslError,
              path: [:phlegethon, :form, :action, name],
              message: "form not defined for action `#{name}`"
          end
        end)
      end

      :ok
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
