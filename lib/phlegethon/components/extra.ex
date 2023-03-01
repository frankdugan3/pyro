defmodule Phlegethon.Components.Extra do
  use Phlegethon.Component

  use Phlegethon.Components.Icon

  @moduledoc """
  Original components provided by Phlegethon.
  """

  # import Phlegethon.Component.Core, only: [flash: 1]

  @doc """
  Renders a code block.
  """
  @doc type: :component

  overridable :class, :class,
    required: true,
    doc: "Merge/override default classes of the `code` element"

  attr :source, :string, required: true, doc: "The code snippet"

  attr :language, :string,
    default: "elixir",
    values: ~w[elixir heex html none],
    doc: "Language of the code snippet"

  def code(assigns) do
    ~H"""
    <code class={@class} phx-no-format><%= format_code(@source, @language) %></code>
    """
  end

  defp format_code(source, language) do
    case language do
      "none" -> source
      lexer -> Makeup.highlight_inner_html(source, lexer: lexer)
    end
    |> Phoenix.HTML.raw()
  end

  @doc """
  A progress element. Styling the progress element is tricky, so this wraps it with some nice conveniences.
  """
  @doc type: :component

  overridable :class, :class, required: true, doc: "The class of the progress bar"

  overridable :size, :string,
    required: true,
    values: :sizes,
    doc: "The size of the progress bar"

  overridable :color, :string,
    required: true,
    values: :colors,
    doc: "The color of the progress bar"

  attr :max, :integer, default: 100
  attr :value, :integer, default: 0
  attr :rest, :global

  def progress(assigns) do
    ~H"""
    <progress value={@value} max={@max} class={@class} {@rest} />
    """
  end

  @doc """
  A tooltip component.

  - JS hook that "nudges" tooltip into view
  - Simple props for tooltip text and custom icon
  - Optional slots for icon and/or tooltip content

  ## Examples

      <.tooltip id="tooltip-1" tooltip="A default tooltip!" />
      <.tooltip id="tooltip-2"
                icon_name={:light_bulb}
                tooltip="Custom icon." />
      <.tooltip id="tooltip-3">
        <:icon>?</:icon>
        <div class="bg-red-500 text-white p-4 w-48 shadow-lg rounded">
          Custom tooltip slot and custom icon slot.
        </div>
      </.tooltip>
  """
  overridable :class, :class, required: true
  overridable :tooltip_class, :class, required: true
  overridable :tooltip_text_class, :class, required: true
  overridable :icon_class, :class
  overridable :horizontal_offset, :string, required: true
  overridable :vertical_offset, :string, required: true
  overridable :icon_kind, :atom, values: @icon_kind_options, required: true
  overridable :icon_name, :atom, values: @icon_name_options, required: true

  attr :id, :string, required: true
  attr :tooltip, :string, default: nil

  slot :icon
  slot :inner_block

  def tooltip(assigns) do
    assigns[:tooltip] || assigns[:inner_block] ||
      raise ArgumentError, "missing :tooltip assign or :inner_block slot"

    ~H"""
    <span id={@id} class={@class}>
      <%= if assigns[:icon] !== [] do %>
        <%= render_slot(@icon) %>
      <% else %>
        <.icon kind={@icon_kind} name={@icon_name} class={@icon_class} />
      <% end %>
      <span
        id={@id <> "-tooltip-text"}
        class={@tooltip_text_class}
        data-vertical-offset={@vertical_offset}
        data-horizontal-offset={@horizontal_offset}
        phx-hook="PhlegethonNudgeIntoView"
      >
        <%= if assigns[:inner_block] !== [] do %>
          <%= render_slot(@inner_block) %>
        <% else %>
          <span class={@tooltip_class} phx-no-format><%= @tooltip %></span>
        <% end %>
      </span>
    </span>
    """
  end
end
