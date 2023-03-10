defmodule Phlegethon.Components.Extra do
  use Phlegethon.Component

  @moduledoc """
  Original components provided by Phlegethon.
  """

  @doc """
  Renders a link. This basically wraps `Phoenix.Component.link/1` with some overridable attributes, in particular `class` for consistent, DRY link default styling.
  """
  @doc type: :component

  attr :class, :any, doc: "Merge/override default classes of the `code` element"

  attr :replace, :boolean,
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
    assigns =
      assigns
      |> assign_overridable(:class, class?: true, required?: true)
      |> assign_overridable(:replace, required?: true)

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

  @doc """
  Renders a code block.
  """
  @doc type: :component

  attr :class, :any, doc: "Merge/override default classes of the `code` element"
  attr :source, :string, required: true, doc: "The code snippet"

  attr :language, :string,
    default: "elixir",
    values: ~w[elixir heex html none],
    doc: "Language of the code snippet"

  def code(assigns) do
    assigns = assign_overridable(assigns, :class, class?: true, required?: true)

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
  Renders a navigation link, taking into account whether the URI is the current page.
  """
  @doc type: :component

  attr :class, :any, doc: "The class of the navigation link"
  attr :is_current, :boolean, doc: "Does `:uri` match `:current_uri`?"
  attr :label, :string, required: true, doc: "The label of of the link"
  attr :uri, :string, required: true, doc: "The URI of the link"
  attr :current_uri, :string, required: true, doc: "The current URI of the page"

  def nav_link(assigns) do
    assigns =
      assigns
      |> assign_overridable(:is_current, required?: true)
      |> assign_overridable(:class, class?: true, required?: true)

    ~H"""
    <.link :if={!@is_current} class={@class} navigate={@uri}>
      <%= @label %>
    </.link>
    <span :if={@is_current} class={@class}>
      <%= @label %>
    </span>
    """
  end

  @doc """
  A progress element. Styling the progress element is tricky, so this wraps it with some nice conveniences.
  """
  @doc type: :component

  attr :class, :any, doc: "The class of the progress bar"
  attr :color, :string, doc: "The color of the progress bar"
  attr :max, :integer, default: 100
  attr :size, :string, doc: "The size of the progress bar"
  attr :value, :integer, default: 0
  attr :rest, :global

  def progress(assigns) do
    assigns =
      assigns
      |> assign_overridable(:class, class?: true, required?: true)
      |> assign_overridable(:size, values: :sizes, required?: true)
      |> assign_overridable(:color, values: :colors, required?: true)

    ~H"""
    <progress value={@value} max={@max} class={@class} {@rest} />
    """
  end

  @doc """
  A simple spinner component.
  """
  @doc type: :component

  attr :class, :any
  attr :show, :boolean, default: true, doc: "Show or hide spinner"
  attr :size, :string, doc: "The size of the spinner"
  attr :rest, :global

  def spinner(assigns) do
    assigns =
      assigns
      |> assign_overridable(:class, class?: true, required?: true)
      |> assign_overridable(:size, values: :sizes, required?: true)

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
                icon_name="hero-light-bulb-solid"
                tooltip="Custom icon." />
      <.tooltip id="tooltip-3">
        <:icon>?</:icon>
        <div class="bg-red-500 text-white p-4 w-48 shadow-lg rounded">
          Custom tooltip slot and custom icon slot.
        </div>
      </.tooltip>
  """
  attr :class, :any
  attr :tooltip_class, :any
  attr :tooltip_text_class, :any
  attr :icon_class, :any
  attr :horizontal_offset, :string
  attr :vertical_offset, :string

  attr :icon_name, :string,
    doc: "The name of the icon; see [`icon/1`](`Phlegethon.Components.Core.icon/1`) for details"

  attr :id, :string, required: true
  attr :tooltip, :string, default: nil

  slot :icon
  slot :inner_block

  def tooltip(assigns) do
    assigns =
      assigns
      |> assign_overridable(:horizontal_offset, required?: true)
      |> assign_overridable(:icon_name, required?: true)
      |> assign_overridable(:vertical_offset, required?: true)
      |> assign_overridable(:class, class?: true, required?: true)
      |> assign_overridable(:icon_class, class?: true)
      |> assign_overridable(:tooltip_class, class?: true, required?: true)
      |> assign_overridable(:tooltip_text_class, class?: true, required?: true)

    assigns[:tooltip] || assigns[:inner_block] ||
      raise ArgumentError, "missing :tooltip assign or :inner_block slot"

    ~H"""
    <span id={@id} class={@class}>
      <%= if assigns[:icon] !== [] do %>
        <%= render_slot(@icon) %>
      <% else %>
        <Phlegethon.Components.Core.icon name={@icon_name} class={@icon_class} />
      <% end %>
      <span
        id={@id <> "-tooltip"}
        class={@tooltip_class}
        data-vertical-offset={@vertical_offset}
        data-horizontal-offset={@horizontal_offset}
        phx-hook="PhlegethonNudgeIntoView"
      >
        <%= if assigns[:inner_block] !== [] do %>
          <%= render_slot(@inner_block) %>
        <% else %>
          <span class={@tooltip_text_class} phx-no-format><%= @tooltip %></span>
        <% end %>
      </span>
    </span>
    """
  end
end
