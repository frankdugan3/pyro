if Code.ensure_loaded?(AshPhoenix) do
  defmodule Pyro.Components.SmartForm do
    @moduledoc """
    A smart component that auto-renders Forms for Ash from a given pyro DSL configuration.
    """

    use Pyro.Component

    # import Pyro.Gettext
    import Pyro.Components.Core, only: [button: 1, header: 1, input: 1]

    alias Pyro.Resource.Info, as: UI
    alias Ash.Resource.Info, as: ResourceInfo

    require Ash.Query

    @doc """
    Renders a smart Ash form.
    """

    attr :overrides, :list, default: nil, doc: @overrides_attr_doc
    attr :action_info, :any, default: :unassigned
    attr :pyro_form, :any, default: :unassigned
    attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"
    attr :for, :map, required: true, doc: "the datastructure for the form"
    attr :resource, :atom, required: true, doc: "the resource of the form"
    attr :actor, :map, default: nil, doc: "the actor to be passed to actions"
    attr :autocomplete, :string, overridable: true, required: true
    attr :actions_class, :css_classes, overridable: true, required: true
    attr :class, :css_classes, overridable: true, required: true
    slot :actions, doc: "extra form actions"

    attr :rest, :global,
      include: ~w(name rel action enctype method novalidate target),
      doc: "the arbitrary HTML attributes to apply to the form tag"

    def smart_form(%{action_info: :unassigned, for: %{action: action}} = assigns) do
      assigns
      |> assign(:action_info, ResourceInfo.action(assigns[:resource], action))
      |> smart_form()
    end

    def smart_form(%{pyro_form: :unassigned, for: %{action: action}} = assigns) do
      assigns
      |> assign(:pyro_form, UI.form_for(assigns[:resource], action))
      |> smart_form()
    end

    def smart_form(assigns) do
      assigns = assign_overridables(assigns)

      ~H"""
      <.form :let={f} class={@class} for={@for} as={@as} autocomplete={@autocomplete} {@rest}>
        <.header overrides={@overrides}>
          <%= @pyro_form.label %>
          <:subtitle :if={@pyro_form.description || @action_info.description}>
            <%= @pyro_form.description || @action_info.description %>
          </:subtitle>
        </.header>

        <%= for field <- @pyro_form.fields do %>
          <.render_field
            overrides={@overrides}
            actor={@actor}
            resource={@resource}
            action_info={@action_info}
            field={field}
            form={f}
          />
        <% end %>

        <section class={@actions_class}>
          <%= for action <- @actions do %>
            <%= render_slot(action, f) %>
          <% end %>
          <.button
            overrides={@overrides}
            disabled={!f.source.changed?}
            size="lg"
            phx-click={"reset_#{f.name}"}
            color="red"
            confirm="Are you sure you want to reset the form?"
          >
            reset
          </.button>
          <.button overrides={@overrides} disabled={!f.source.valid?} size="lg" type="submit">
            <%= if f.source.valid?, do: "Save", else: "Incomplete" %>
          </.button>
        </section>
      </.form>
      """
    end

    attr :overrides, :list, default: nil, doc: @overrides_attr_doc
    attr :actor, :map, default: nil, doc: "the actor to be passed to actions"
    attr :resource, :atom, required: true, doc: "the resource of the form"
    attr :action_info, :map, required: true
    attr :field, :map, required: true, doc: "the pyro field/field_group"
    attr :form, :map, required: true, doc: "the form"
    attr :attribute, Ash.Resource.Attribute, default: nil
    attr :argument, Ash.Resource.Actions.Argument, default: nil
    attr :change, :map, default: nil
    attr :field_group_class, :css_classes, overridable: true, required: true
    attr :field_group_label_class, :css_classes, overridable: true, required: true

    defp render_field(
           %{
             attribute: nil,
             argument: nil,
             resource: resource,
             action_info: action_info,
             field: %Pyro.Resource.Form.Field{name: name}
           } = assigns
         ) do
      {attribute, argument} =
        case Enum.find(action_info.arguments, &(&1.name == name)) do
          nil -> {ResourceInfo.attribute(resource, name), nil}
          argument -> {nil, argument}
        end

      change = extract_change(argument, resource, action_info)

      if !attribute && !argument do
        raise "Unable to find attribute or argument #{name}"
      end

      multiple =
        case {attribute, argument} do
          {%{type: {:array, _}}, _} -> true
          {_, %{type: {:array, _}}} -> true
          _ -> false
        end

      assigns
      |> assign(:attribute, attribute)
      |> assign(:argument, argument)
      |> assign(:multiple, multiple)
      |> assign(:change, change)
      |> render_field
    end

    defp render_field(%{field: %Pyro.Resource.Form.FieldGroup{}} = assigns) do
      assigns = assign_overridables(assigns)

      ~H"""
      <fieldset class={@field_group_class}>
        <legend :if={@field.label} class={@field_group_label_class}>
          <%= @field.label %>
        </legend>
        <%= for child_field <- @field.fields do %>
          <.render_field
            overrides={@overrides}
            resource={@resource}
            action_info={@action_info}
            actor={@actor}
            field={child_field}
            form={@form}
          />
        <% end %>
      </fieldset>
      """
    end

    defp render_field(%{field: %Pyro.Resource.Form.Field{type: :select}} = assigns) do
      ~H"""
      <.input
        overrides={@overrides}
        field={@form[@field.name]}
        type="select"
        multiple={@multiple}
        class={@field.class}
        options={@field.options}
        input_class={@field.input_class}
        label={@field.label}
        autofocus={@field.autofocus}
        description={@field.description || @attribute.description}
      />
      """
    end

    defp render_field(%{field: %Pyro.Resource.Form.Field{type: :long_text}} = assigns) do
      ~H"""
      <.input
        overrides={@overrides}
        field={@form[@field.name]}
        type="textarea"
        class={@field.class}
        input_class={@field.input_class}
        label={@field.label}
        autofocus={@field.autofocus}
        description={@field.description || @attribute.description}
      />
      """
    end

    defp render_field(%{field: %Pyro.Resource.Form.Field{type: :short_text}} = assigns) do
      ~H"""
      <.input
        overrides={@overrides}
        field={@form[@field.name]}
        class={@field.class}
        input_class={@field.input_class}
        label={@field.label}
        autofocus={@field.autofocus}
        description={@field.description || @attribute.description}
      />
      """
    end

    defp render_field(
           %{
             field: %Pyro.Resource.Form.Field{type: :default},
             attribute: %{type: type}
           } = assigns
         )
         when type in [Ash.Type.String, Ash.Type.CiString] do
      ~H"""
      <.input
        overrides={@overrides}
        field={@form[@field.name]}
        class={@field.class}
        input_class={@field.input_class}
        label={@field.label}
        autofocus={@field.autofocus}
        description={@field.description || @attribute.description}
      />
      """
    end

    defp render_field(
           %{
             field: %Pyro.Resource.Form.Field{type: :default},
             attribute: %{type: type, constraints: constraints}
           } = assigns
         )
         when type in [Ash.Type.Atom] do
      # TODO: This needs to be considered. Do we require options from the Pyro config if `one_of` not defined? Do we allow arbitrary string input?
      assigns =
        assigns
        |> assign(
          :options,
          case Keyword.get(constraints, :one_of) do
            nil -> []
            options -> options
          end
        )

      ~H"""
      <.input
        overrides={@overrides}
        field={@form[@field.name]}
        type="select"
        options={@options}
        class={@field.class}
        input_class={@field.input_class}
        label={@field.label}
        autofocus={@field.autofocus}
        description={@field.description || @attribute.description}
      />
      """
    end

    defp render_field(
           %{
             field: %Pyro.Resource.Form.Field{type: :default},
             attribute: %{type: type}
           } = assigns
         )
         when type in [Ash.Type.Boolean] do
      ~H"""
      <.input
        overrides={@overrides}
        field={@form[@field.name]}
        type="checkbox"
        class={@field.class}
        input_class={@field.input_class}
        label={@field.label}
        autofocus={@field.autofocus}
        description={@field.description || @attribute.description}
      />
      """
    end

    defp render_field(
           %{
             field: %Pyro.Resource.Form.Field{type: type},
             argument: %Ash.Resource.Actions.Argument{type: arg_type},
             change: %{
               type: Ash.Resource.Change.ManageRelationship,
               manage_opts: %{
                 on_lookup: {:relate, _, _}
               },
               relationship: %{
                 api: api
               }
             }
           } = assigns
         )
         when type in [:default, :autocomplete] and
                arg_type in [
                  Ash.Type.UUID,
                  Ash.Type.Atom,
                  Ash.Type.Binary,
                  Ash.Type.CiString,
                  Ash.Type.String,
                  Ash.Type.Integer
                ] do
      if is_nil(api),
        do:
          raise("""
          #{__MODULE__}.render_field/1:
          - field name #{inspect(assigns.field.name)}
          - field type #{inspect(assigns.field.type)}
          - relationship #{inspect(assigns.change.relationship.name)} is missing API

          Add API option to relationship:
            api: MyApp.MyContext.Api
          """)

      ~H"""
      <.live_component
        module={Pyro.Components.Autocomplete}
        id={"#{@form.id}-#{@field.name}-autocomplete"}
        overrides={@overrides}
        field={@form[@field.name]}
        class={@field.class}
        input_class={@field.input_class}
        label={@field.label}
        autofocus={@field.autofocus}
        prompt={@field.prompt}
        description={@field.description || @argument.description}
        option_label_key={@field.autocomplete_option_label_key}
        option_value_key={@field.autocomplete_option_value_key}
        search_fn={
          fn search ->
            @change.relationship.destination
            |> Ash.Query.for_read(
              @field.autocomplete_search_action,
              Map.new([{@field.autocomplete_search_arg, search}]),
              actor: @actor
            )
            |> @change.relationship.api.read!()
          end
        }
        lookup_fn={
          {_, _, lookup_action} = @change.manage_opts.on_lookup

          fn value ->
            @change.relationship.destination
            |> Ash.Query.for_read(
              lookup_action,
              actor: @actor
            )
            |> Ash.Query.filter([{@field.autocomplete_option_value_key, value}])
            |> Ash.Query.load([@field.autocomplete_option_label_key])
            |> @change.relationship.api.read_one!()
          end
        }
      />
      """
    end

    defp render_field(%{attribute: %Ash.Resource.Attribute{type: type}} = assigns) do
      raise """
      No #{__MODULE__}.render_field/1 pattern to match:
        - field type #{inspect(assigns.field.type)}
        - attribute type #{inspect(type)}
      """

      ~H"""
      <div />
      """
    end

    defp render_field(%{argument: %Ash.Resource.Actions.Argument{type: type}} = assigns) do
      raise """
      No #{__MODULE__}.render_field/1 pattern to match:
        - field type #{inspect(assigns.field.type)}
        - argument type #{inspect(type)}
      """

      ~H"""
      <div />
      """
    end

    defp extract_change(%Ash.Resource.Actions.Argument{name: name}, resource, action_info) do
      Enum.reduce_while(action_info.changes, nil, fn
        %{change: {Ash.Resource.Change.ManageRelationship, manage_opts}}, _ ->
          process_change(manage_opts, name, resource)

        _, acc ->
          {:cont, acc}
      end)
    end

    defp extract_change(_, _, _), do: nil

    defp process_change(manage_opts, name, resource) do
      if manage_opts[:argument] == name do
        relationship = Ash.Resource.Info.relationship(resource, manage_opts[:relationship])

        # Extract expanded management options
        manage_opts = manage_opts[:opts] || []

        {defaults, manage_opts} = get_defaults_and_options(manage_opts)

        manage_opts =
          Ash.Changeset.ManagedRelationshipHelpers.sanitize_opts(
            relationship,
            Keyword.merge(defaults, manage_opts)
          )
          |> Enum.into(%{})

        change = %{
          type: Ash.Resource.Change.ManageRelationship,
          relationship: relationship,
          manage_opts: manage_opts
        }

        {:halt, change}
      else
        {:cont, nil}
      end
    end

    defp get_defaults_and_options(manage_opts) do
      {type, opts} = Keyword.pop(manage_opts, :type)
      defaults = (type && Ash.Changeset.manage_relationship_opts(type)) || []
      {defaults, opts}
    end
  end
end
