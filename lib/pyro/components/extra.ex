defmodule Pyro.Components.Extra do
  use Pyro.Component

  # import Pyro.Gettext

  @moduledoc """
  Original components provided by Pyro.
  """

  @doc """
  Renders a link. This basically wraps `Phoenix.Component.link/1` with some overridable attributes, in particular `class` for consistent, DRY link default styling.
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc

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
    doc: "a boolean or custom token to use for links with an HTTP method other than `get`"

  attr :replace, :boolean,
    overridable: true,
    required: true,
    doc:
      "when using `:patch` or `:navigate`, should the browser's history be replaced with `pushState`?"

  attr :class, :tails_classes,
    overridable: true,
    required: true,
    doc: "merge/override default classes of the `code` element"

  attr :rest, :global, doc: "additional HTML attributes added to the `a` tag"

  slot :inner_block,
    required: true,
    doc: "the content rendered inside of the `a` tag"

  def a(assigns) do
    assigns = assign_overridables(assigns)

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

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :source, :string, required: true, doc: "the code snippet"
  attr :id, :string, required: true
  attr :copy, :boolean, overridable: true, required: true
  attr :copy_label, :string, overridable: true, required: true
  attr :copy_class, :tails_classes, overridable: true, required: true
  attr :copy_message, :string, overridable: true

  attr :language, :string,
    default: "elixir",
    values: ~w[elixir heex html none],
    doc: "language of the code snippet"

  attr :class, :tails_classes,
    overridable: true,
    required: true,
    doc: "merge/override default classes of the `code` element"

  def code(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <code class={@class} phx-no-format><.copy_to_clipboard :if={@copy} id={@id <> "-copy-btn"} value={@source} message={@copy_message} label={@copy_label} icon_name="hero-code-bracket" class={@copy_class} /><%= format_code(@source, @language) %></code>
    """
  end

  defp format_code(source, language) do
    case language do
      "none" -> source
      lexer -> Makeup.highlight_inner_html(source, lexer: lexer)
    end
    |> Phoenix.HTML.raw()
  end

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :id, :string, required: true
  attr :value, :string, required: true, doc: "text to copy"
  attr :label, :string, default: nil, doc: "button label, defaults to value"
  attr :disabled, :boolean, default: false

  attr :icon_name, :string,
    default: nil,
    doc:
      "the name of the icon to display (nil for none); see [`icon/1`](`Pyro.Components.Core.icon/1`) for details"

  attr :ttl, :integer,
    overridable: true,
    required: true,
    doc: "how long to show the flash message after copying"

  attr :case, :string,
    overridable: true,
    required: true,
    values: ~w[uppercase normal-case lowercase capitalize],
    doc: "the case of the text"

  attr :color, :string, overridable: true, required: true, doc: "the color of the button"
  attr :shape, :string, overridable: true, required: true, doc: "shape of the button"
  attr :size, :string, overridable: true, required: true, doc: "the size of the button"
  attr :variant, :string, overridable: true, required: true, doc: "style of button"
  attr :class, :tails_classes, overridable: true, required: true

  attr :message, :string,
    overridable: true,
    required: true,
    doc: "message to display after copying"

  attr :icon_class, :tails_classes, overridable: true, required: true
  attr :rest, :global

  def copy_to_clipboard(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <button
      id={@id}
      type="button"
      class={@class}
      disabled={@disabled}
      phx-hook="PyroCopyToClipboard"
      data-value={@value}
      data-message={@message}
      data-ttl={@ttl}
      title="Copy to clipboard"
      {@rest}
    >
      <Pyro.Components.Core.icon
        :if={@icon_name}
        overrides={@overrides}
        name={@icon_name}
        class={@icon_class}
      />
      <%= @label || @value %>
    </button>
    """
  end

  @doc """
  Renders a navigation link, taking into account whether the URI is the current page.
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :label, :string, required: true, doc: "the label of of the link"
  attr :uri, :string, required: true, doc: "the URI of the link"
  attr :current_uri, :string, required: true, doc: "the current URI of the page"

  attr :is_current, :boolean,
    overridable: true,
    required: true,
    doc: "does `:uri` match `:current_uri`?"

  attr :class, :tails_classes,
    overridable: true,
    required: true,
    doc: "the class of the navigation link"

  def nav_link(assigns) do
    assigns = assign_overridables(assigns)

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

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :max, :integer, default: 100
  attr :value, :integer, default: 0
  attr :color, :string, overridable: true, required: true, doc: "the color of the progress bar"
  attr :size, :string, overridable: true, required: true, doc: "the size of the progress bar"

  attr :class, :tails_classes,
    overridable: true,
    required: true,
    doc: "the class of the progress bar"

  attr :rest, :global

  def progress(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <progress value={@value} max={@max} class={@class} {@rest} />
    """
  end

  @doc """
  A simple spinner component.
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :show, :boolean, default: true, doc: "show or hide spinner"
  attr :rest, :global
  attr :size, :string, overridable: true, required: true, doc: "the size of the spinner"
  attr :class, :tails_classes, overridable: true, required: true

  def spinner(assigns) do
    assigns = assign_overridables(assigns)

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

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :id, :string, required: true
  attr :tooltip, :string, default: nil
  attr :vertical_offset, :string, overridable: true, required: true
  attr :horizontal_offset, :string, overridable: true, required: true
  attr :tooltip_class, :tails_classes, overridable: true, required: true
  attr :tooltip_text_class, :tails_classes, overridable: true, required: true
  attr :icon_class, :tails_classes, overridable: true

  attr :icon_name, :string,
    overridable: true,
    required: true,
    doc: "the name of the icon; see [`icon/1`](`Pyro.Components.Core.icon/1`) for details"

  attr :class, :tails_classes, overridable: true, required: true

  slot :icon
  slot :inner_block

  def tooltip(assigns) do
    assigns = assign_overridables(assigns)

    assigns[:tooltip] || assigns[:inner_block] ||
      raise ArgumentError, "missing :tooltip assign or :inner_block slot"

    ~H"""
    <span id={@id} class={@class}>
      <%= if assigns[:icon] !== [] do %>
        <%= render_slot(@icon) %>
      <% else %>
        <Pyro.Components.Core.icon overrides={@overrides} name={@icon_name} class={@icon_class} />
      <% end %>
      <span
        id={@id <> "-tooltip"}
        class={@tooltip_class}
        data-vertical-offset={@vertical_offset}
        data-horizontal-offset={@horizontal_offset}
        phx-hook="PyroNudgeIntoView"
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

  @doc """
  A color theme switch component.

  - Toggle through light, dark, and system color themes
  - Optionally show labels for each theme
  - Optionally override the default labels for each theme with `label_system`, `label_dark`, and `label_light`
  - Optionally override the default icons for each theme with `icon_system`, `icon_dark`, and `icon_light`

  ## Examples

      <.color_theme_switcher />

      <.color_theme_switcher theme="light" />
      <.color_theme_switcher theme="dark" />
      <.color_theme_switcher theme="system" />

      <.color_theme_switcher show_labels />

      <.color_theme_switcher label_system="System" label_dark="Dunkel" label_light="Hell" />
      <.color_theme_switcher icon_system="hero-computer-desktop-solid" icon_dark="hero-moon-solid" icon_light="hero-sun-solid" />
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :class, :tails_classes, overridable: true, required: true
  attr :theme, :atom, overridable: true, required: true, doc: "the theme used to initialize the color theme switcher"

  attr :label_system, :string, overridable: true, required: false, doc: "the label for the system theme"
  attr :label_dark, :string, overridable: true, required: false, doc: "the label for the dark theme"
  attr :label_light, :string, overridable: true, required: false, doc: "the label for the light theme"

  attr :icon_system, :string, overridable: true, required: false, doc: "the icon for the system theme"
  attr :icon_dark, :string, overridable: true, required: false, doc: "the icon for the dark theme"
  attr :icon_light, :string, overridable: true, required: false, doc: "the icon for the light theme"

  attr :show_labels, :boolean, default: false, doc: "show or hide labels"

  def color_theme_switcher(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <Pyro.Components.Core.button
      id={Ecto.UUID.generate()}
      class={@class}
      phx-hook="PyroColorThemeHook"
      theme={@theme}
    >
      <div class="color-theme-system-icon">
        <Pyro.Components.Core.icon name={@icon_system} />
        <span :if={@show_labels}> <%= @label_system %></span>
      </div>
      <div class="color-theme-dark-icon hidden">
        <Pyro.Components.Core.icon name={@icon_dark} />
        <span :if={@show_labels}> <%= @label_dark %></span>
      </div>
      <div class="color-theme-light-icon hidden">
        <Pyro.Components.Core.icon name={@icon_light} />
        <span :if={@show_labels}> <%= @label_light %></span>
      </div>
    </Pyro.Components.Core.button>
    """
  end
end
