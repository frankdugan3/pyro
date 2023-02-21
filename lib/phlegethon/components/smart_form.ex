defmodule Phlegethon.Components.SmartForm do
  use Phlegethon.Component

  alias Phlegethon.Info, as: UI

  import Phlegethon.Components.Core, only: [button: 1, header: 1, input: 1]

  @doc """
  Renders a smart Ash form.
  """
  @doc type: :component

  overridable :class, :class, required: true
  overridable :actions_class, :class, required: true
  overridable :action_info, :map, required: true, assign_new: true
  overridable :phlegethon_form, :map, required: true, assign_new: true
  overridable :autocomplete, :string, required: true
  attr :resource, :atom, required: true, doc: "The resource of the form"
  attr :action, :atom, required: true, doc: "The action to be used"
  attr :for, :map, required: true, doc: "The datastructure for the form"
  attr :as, :any, default: nil, doc: "The server side parameter to collect all input under"
  # TODO: We obviously need to require the actor and use it to filter the UI
  # attr :actor, :map, default: nil, doc: "The actor to be passed to the action"
  attr :rest, :global,
    include: ~w(name rel action enctype method novalidate target),
    doc: "The arbitrary HTML attributes to apply to the form tag"

  def smart_form(assigns) do
    ~H"""
    <.form :let={f} class={@class} for={@for} as={@as} autocomplete={@autocomplete} {@rest}>
      <.header>
        <%= @phlegethon_form.label %> <%= UI.resource_label(@resource) %>
        <:subtitle :if={@phlegethon_form.description || @action_info.description}>
          <%= @phlegethon_form.description || @action_info.description %>
        </:subtitle>
      </.header>

      <%= for field <- @phlegethon_form.fields do %>
        <.render_field resource={@resource} field={field} form={f} />
      <% end %>

      <section class={@actions_class}>
        <.button
          disabled={!f.source.changed?}
          size="lg"
          phx-click={"reset_#{f.name}"}
          color="red"
          confirm="Are you sure you want to reset the form?"
        >
          reset
        </.button>
        <.button disabled={!f.source.valid?} size="lg" type="submit">
          <%= if f.source.valid?, do: "Save", else: "Incomplete" %>
        </.button>
      </section>
    </.form>
    """
  end

  overridable :field_group_class, :class, required: true
  overridable :field_group_label_class, :class, required: true
  overridable :attribute, Ash.Resource.Attribute, assign_new: true
  attr :resource, :atom, required: true, doc: "The resource of the form"
  attr :field, :map, required: true, doc: "The phlegethon field"
  attr :form, :map, required: true, doc: "The form"

  defp render_field(%{field: %Phlegethon.Resource.Form.FieldGroup{}} = assigns) do
    ~H"""
    <fieldset class={@field_group_class}>
      <legend :if={@field.label} class={@field_group_label_class}>
        <%= @field.label %>
      </legend>
      <%= for child_field <- @field.fields do %>
        <.render_field resource={@resource} field={child_field} form={@form} />
      <% end %>
    </fieldset>
    """
  end

  defp render_field(%{field: %Phlegethon.Resource.Form.Field{type: :long_text}} = assigns) do
    ~H"""
    <.input
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
      field={@form[@field.name]}
      class={@field.class}
      input_class={@field.input_class}
      label={@field.label}
      autofocus={@field.autofocus}
      description={@field.description || @attribute.description}
    />
    """
  end

  defp render_field(assigns) do
    ~H"""
    <div />
    """
  end
end
