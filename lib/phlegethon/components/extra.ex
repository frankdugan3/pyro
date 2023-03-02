defmodule Phlegethon.Components.Extra do
  use Phlegethon.Component

  use Phlegethon.Components.Icon

  @doc """
  Renders a link. This basically wraps `Phoenix.Component.link/1` with some overridable attributes, in particular `class` for consistent, DRY link default styling.
  """
  @doc type: :component

  overridable :class, :class,
    required: true,
    doc: "Merge/override default classes of the `code` element"

  overridable :replace, :boolean,
    required: true,
    doc: """
    When using `:patch` or `:navigate`,
    should the browser's history be replaced with `pushState`?
    """

  attr :navigate, :string,
    default: nil,
    doc: """
    Navigates from a LiveView to a new LiveView.
    The browser page is kept, but a new LiveView process is mounted and its content on the page
    is reloaded. It is only possible to navigate between LiveViews declared under the same router
    `Phoenix.LiveView.Router.live_session/3`. Otherwise, a full browser redirect is used.
    """

  attr :patch, :string,
    default: nil,
    doc: """
    Patches the current LiveView.
    The `handle_params` callback of the current LiveView will be invoked and the minimum content
    will be sent over the wire, as any other LiveView diff.
    """

  attr :href, :any,
    default: nil,
    doc: """
    Uses traditional browser navigation to the new location.
    This means the whole page is reloaded on the browser.
    """

  attr :method, :string,
    default: "get",
    doc: """
    The HTTP method to use with the link. This is intended for usage outside of LiveView
    and therefore only works with the `href={...}` attribute. It has no effect on `patch`
    and `navigate` instructions.
    In case the method is not `get`, the link is generated inside the form which sets the proper
    information. In order to submit the form, JavaScript must be enabled in the browser.
    """

  attr :csrf_token, :any,
    default: true,
    doc: """
    A boolean or custom token to use for links with an HTTP method other than `get`.
    """

  attr :rest, :global,
    doc: """
    Additional HTML attributes added to the `a` tag.
    """

  slot :inner_block,
    required: true,
    doc: """
    The content rendered inside of the `a` tag.
    """

  def a(assigns) do
    ~H"""
    <.link
      class={@class}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      replace={@replace}
      method={@method}
      csrf_token={@csrf_token}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

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
  A simple spinner component.
  """
  @doc type: :component

  overridable :class, :class, required: true

  overridable :size, :string,
    required: true,
    values: :sizes,
    doc: "The size of the spinner"

  attr :show, :boolean, default: true, doc: "Show or hide spinner"
  attr :rest, :global

  def spinner(assigns) do
    ~H"""
    <svg {@rest} class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
      <path
        class="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      />
    </svg>
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

  overridable :icon_kind, :atom,
    values: @icon_kind_options,
    required: true,
    doc: "The kind of the icon; see [`icon/1`](`Phlegethon.Components.Icon.icon/1`) for details"

  overridable :icon_name, :atom,
    values: @icon_name_options,
    required: true,
    doc: "The name of the icon; see [`icon/1`](`Phlegethon.Components.Icon.icon/1`) for details"

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
