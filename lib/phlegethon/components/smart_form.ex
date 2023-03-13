defmodule Phlegethon.Components.SmartForm do
  use Phlegethon.Component

  alias Phlegethon.Info, as: UI

  import Phlegethon.Components.Core, only: [button: 1, header: 1, input: 1]

  @doc """
  Renders a smart Ash form.
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :action_info, :map, default: nil
  attr :phlegethon_form, :map, default: nil
  attr :action, :atom, required: true, doc: "The action to be used"
  attr :as, :any, default: nil, doc: "The server side parameter to collect all input under"
  attr :for, :map, required: true, doc: "The datastructure for the form"
  attr :resource, :atom, required: true, doc: "The resource of the form"
  # TODO: We obviously need to require the actor and use it to filter the UI
  # attr :actor, :map, default: nil, doc: "The actor to be passed to the action"

  attr :autocomplete, :string, overridable: true, required: true
  attr :actions_class, :tails_classes, overridable: true, required: true
  attr :class, :tails_classes, overridable: true, required: true

  attr :rest, :global,
    include: ~w(name rel action enctype method novalidate target),
    doc: "The arbitrary HTML attributes to apply to the form tag"

  def smart_form(%{action_info: nil} = assigns) do
    assigns
    |> assign(:action_info, UI.action(assigns[:resource], assigns[:action]))
    |> smart_form()
  end

  def smart_form(%{phlegethon_form: nil} = assigns) do
    assigns
    |> assign(:phlegethon_form, UI.form_for(assigns[:resource], assigns[:action]))
    |> smart_form()
  end

  def smart_form(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <.form :let={f} class={@class} for={@for} as={@as} autocomplete={@autocomplete} {@rest}>
      <.header overrides={@overrides}>
        <%= @phlegethon_form.label %> <%= UI.resource_label(@resource) %>
        <:subtitle :if={@phlegethon_form.description || @action_info.description}>
          <%= @phlegethon_form.description || @action_info.description %>
        </:subtitle>
      </.header>

      <%= for field <- @phlegethon_form.fields do %>
        <.render_field overrides={@overrides} resource={@resource} field={field} form={f} />
      <% end %>

      <section class={@actions_class}>
        <.button
          overrides={@overrides}
          disabled={!f.source.changed?}
          size="lg"
          phx-click={"reset_#{f.name}"}
          color="error"
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
  attr :resource, :atom, required: true, doc: "The resource of the form"
  attr :field, :map, required: true, doc: "The phlegethon field"
  attr :form, :map, required: true, doc: "The form"
  attr :attribute, Ash.Resource.Attribute, default: nil
  attr :field_group_class, :tails_classes, overridable: true, required: true
  attr :field_group_label_class, :tails_classes, overridable: true, required: true

  defp render_field(
         %{attribute: nil, resource: resource, field: %Phlegethon.Resource.Form.Field{name: name}} =
           assigns
       ) do
    assigns
    |> assign(:attribute, UI.attribute(resource, name))
    |> render_field
  end

  defp render_field(%{field: %Phlegethon.Resource.Form.FieldGroup{}} = assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <fieldset class={@field_group_class}>
      <legend :if={@field.label} class={@field_group_label_class}>
        <%= @field.label %>
      </legend>
      <%= for child_field <- @field.fields do %>
        <.render_field overrides={@overrides} resource={@resource} field={child_field} form={@form} />
      <% end %>
    </fieldset>
    """
  end

  defp render_field(%{field: %Phlegethon.Resource.Form.Field{type: :long_text}} = assigns) do
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

  defp render_field(%{field: %Phlegethon.Resource.Form.Field{type: :short_text}} = assigns) do
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
         %{field: %Phlegethon.Resource.Form.Field{type: :default}, attribute: %{type: type}} =
           assigns
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
           field: %Phlegethon.Resource.Form.Field{type: :default},
           attribute: %{type: type, constraints: constraints}
         } = assigns
       )
       when type in [Ash.Type.Atom] do
    # TODO: This needs to be considered. Do we require options from the Phlegethon config if `one_of` not defined? Do we allow arbitrary string intput?
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
         %{field: %Phlegethon.Resource.Form.Field{type: :default}, attribute: %{type: type}} =
           assigns
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

  defp render_field(assigns) do
    # raise "Unknown field type: #{Map.get(assigns[:attribute], :type)}"

    ~H"""
    <div />
    """
  end
end
