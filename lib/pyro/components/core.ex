defmodule Pyro.Components.Core do
  @moduledoc """
  A core set of functional `.heex` components for building web apps. It is similar to (and often API-compatible with) Phoenix's generated `core_components.ex`.

  Compared to Phoenix's generated components, Pyro's implementation adds:

  - Maintenance/bugfixes/new features, since it's a library
  - A powerful [override system](#module-overridable-component-attributes) for customization
  - A special `:css_classes` type that utilizes the configured CSS merge utility
  - The button component implements both button and anchor tags (button-styled links!)
  - Inputs
    - `autofocus` prop to enable a hook for reliable focus on mount
    - `hidden` input type with a slot for custom content
  - A rich flash experience
    - Auto-remove after (configurable) timeout
    - Progress bar for auto-removed flash messages
    - Define which flashes are included in which trays (supports multiple trays)
  - Slightly cleaner, more semantic markup
  - Extra components

  There are more complex components outside the `Core` module, be sure to check those out as well.
  """

  use Pyro.Component

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
    doc: "when using `:patch` or `:navigate`, should the browser's history be replaced with `pushState`?"

  attr :class, :css_classes,
    overridable: true,
    doc: "merge/override default classes of the `code` element"

  attr :rest, :global, doc: "additional HTML attributes added to the `a` tag"
  slot :inner_block, required: true, doc: "the content rendered inside of the `a` tag"

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
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
      <.back icon_name="hero-arrow-left" navigate={~p"/"}>
        Go back to the about page.
      </.back>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc

  attr :icon_name, :string,
    overridable: true,
    required: true,
    doc: "the name of the icon; see `icon/1` for details"

  attr :navigate, :any, required: true
  attr :class, :css_classes, overridable: true
  attr :icon_class, :css_classes, overridable: true

  slot :inner_block, required: true

  def back(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <.link navigate={@navigate} class={@class}>
      <.icon overrides={@overrides} name={@icon_name} class={@icon_class} />
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  @doc """
  Renders a button.

  Supports:

  - Any button type
  - Any anchor type
    - LivePatch
    - LiveRedirect
    - External href links

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
      <.button navigate={~p"/home"}>Home</.button>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc

  attr :confirm, :string,
    default: nil,
    doc: "text to display in a confirm dialog before emitting click event"

  attr :csrf_token, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :href, :any

  attr :icon_name, :string,
    default: nil,
    doc: "the name of the icon to display (nil for none); see `icon/1` for details"

  attr :loading, :boolean, default: false, doc: "display a loading spinner"
  attr :method, :string, default: "get"
  attr :navigate, :string
  attr :patch, :string
  attr :ping, :boolean, default: false, doc: "show a ping indicator"
  attr :replace, :boolean, default: false
  attr :rest, :global, include: ~w[download hreflang referrerpolicy rel target form name value]

  attr :type, :string,
    default: "button",
    values: ~w[button reset submit],
    doc: "type of the button"

  attr :color, :string, overridable: true, required: true, doc: "the color of the button"
  attr :shape, :string, overridable: true, required: true, doc: "shape of the button"
  attr :size, :string, overridable: true, required: true, doc: "the size of the button"
  attr :variant, :string, overridable: true, required: true, doc: "style of button"
  attr :class, :css_classes, overridable: true
  attr :icon_class, :css_classes, overridable: true
  attr :ping_class, :css_classes, overridable: true
  attr :ping_animation_class, :css_classes, overridable: true

  slot :inner_block, required: true, doc: "the content of the button"

  def button(assigns) do
    assigns
    |> assign_overridables()
    |> render_button()
  end

  defp render_button(%{href: _href} = assigns) do
    ~H"""
    <.link
      href={@href}
      replace={@replace}
      method={@method}
      csrf_token={@csrf_token}
      data-confirm={@confirm}
      data-submit={!!@confirm}
      class={@class}
      {@rest}
    >
      <.spinner :if={@loading} overrides={@overrides} size={@size} />
      <.icon
        :if={!@loading && @icon_name}
        overrides={@overrides}
        name={@icon_name}
        class={@icon_class}
      />
      <%= render_slot(@inner_block) %>
      <%= if @ping do %>
        <span class={@ping_animation_class} />
        <span class={@ping_class} />
      <% end %>
    </.link>
    """
  end

  defp render_button(%{patch: _patch} = assigns) do
    ~H"""
    <.link
      patch={@patch}
      replace={@replace}
      data-confirm={@confirm}
      data-submit={!!@confirm}
      class={@class}
      {@rest}
    >
      <.spinner :if={@loading} overrides={@overrides} size={@size} />
      <.icon
        :if={!@loading && @icon_name}
        overrides={@overrides}
        name={@icon_name}
        class={@icon_class}
      />
      <%= render_slot(@inner_block) %>
      <%= if @ping do %>
        <span class={@ping_animation_class} />
        <span class={@ping_class} />
      <% end %>
    </.link>
    """
  end

  defp render_button(%{navigate: _navigate} = assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      replace={@replace}
      data-confirm={@confirm}
      data-submit={!!@confirm}
      class={@class}
      {@rest}
    >
      <.spinner :if={@loading} overrides={@overrides} size={@size} />
      <.icon
        :if={!@loading && @icon_name}
        overrides={@overrides}
        name={@icon_name}
        class={@icon_class}
      />
      <%= render_slot(@inner_block) %>
      <%= if @ping do %>
        <span class={@ping_animation_class} />
        <span class={@ping_class} />
      <% end %>
    </.link>
    """
  end

  defp render_button(assigns) do
    ~H"""
    <button
      type={@type}
      disabled={@disabled}
      data-confirm={@confirm}
      data-submit={!!@confirm}
      class={@class}
      {@rest}
    >
      <.spinner :if={@loading} overrides={@overrides} size={@size} />
      <.icon
        :if={!@loading && @icon_name}
        overrides={@overrides}
        name={@icon_name}
        class={@icon_class}
      />
      <%= render_slot(@inner_block) %>
      <%= if @ping do %>
        <span class={@ping_animation_class} />
        <span class={@ping_class} />
      <% end %>
    </button>
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
  attr :copy_message, :string, overridable: true

  attr :language, :string,
    default: "elixir",
    values: ~w[elixir heex html none],
    doc: "language of the code snippet"

  attr :class, :css_classes,
    overridable: true,
    doc: "merge/override default classes of the `code` element"

  attr :copy_class, :css_classes, overridable: true

  def code(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <code class={@class} phx-no-format><.copy_to_clipboard :if={@copy} id={@id <> "-copy-btn"} value={@source} message={@copy_message} label={@copy_label} icon_name="hero-code-bracket" class={@copy_class} /><%= format_code(@source, @language) %></code>
    """
  end

  if Code.ensure_loaded?(Makeup) do
    defp format_code(source, language) do
      case_result =
        case language do
          "none" -> source
          lexer -> Makeup.highlight_inner_html(source, lexer: lexer)
        end

      Phoenix.HTML.raw(case_result)
    end
  else
    defp format_code(source, _), do: source
  end

  @doc """
  A color scheme switch component.

  - Toggle through light, dark, and system color schemes
  - Optionally show labels for each scheme
  - Optionally override the default labels for each scheme with `label_system`, `label_dark`, and `label_light`
  - Optionally override the default icons for each scheme with `icon_system`, `icon_dark`, and `icon_light`

  > #### Note: {: .info}
  >
  > This requires several things to work:
  >   - `darkMode: 'class'` in your Tailwind config
  >   - `color_scheme_switcher_js/1` added to the page's `<head>` before `app.js`
  >   - Pyro's `PyroColorSchemeHook` hook added to your hooks in `app.js`

  ## Examples

      <.color_scheme_switcher />

      <.color_scheme_switcher scheme="light" />
      <.color_scheme_switcher scheme="dark" />
      <.color_scheme_switcher scheme="system" />

      <.color_scheme_switcher show_labels />

      <.color_scheme_switcher label_system="System" label_dark="Dunkel" label_light="Hell" />
      <.color_scheme_switcher icon_system="hero-computer-desktop-solid" icon_dark="hero-moon-solid" icon_light="hero-sun-solid" />
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc

  attr :scheme, :atom,
    overridable: true,
    required: true,
    doc: "the scheme used to initialize the color scheme switcher"

  attr :label_system, :string, overridable: true, doc: "the label for the system scheme"
  attr :label_dark, :string, overridable: true, doc: "the label for the dark scheme"
  attr :label_light, :string, overridable: true, doc: "the label for the light scheme"
  attr :icon_system, :string, overridable: true, doc: "the icon for the system scheme"
  attr :icon_dark, :string, overridable: true, doc: "the icon for the dark scheme"
  attr :icon_light, :string, overridable: true, doc: "the icon for the light scheme"
  attr :show_labels, :boolean, default: false, doc: "show or hide labels"
  attr :class, :css_classes, overridable: true

  def color_scheme_switcher(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <.button
      id={Ecto.UUID.generate()}
      class={@class}
      phx-hook="PyroColorSchemeHook"
      data-scheme={@scheme}
    >
      <div class="color-scheme-system-icon">
        <.icon name={@icon_system} />
        <span :if={@show_labels}><%= @label_system %></span>
      </div>
      <div class="color-scheme-dark-icon hidden">
        <.icon name={@icon_dark} />
        <span :if={@show_labels}><%= @label_dark %></span>
      </div>
      <div class="color-scheme-light-icon hidden">
        <.icon name={@icon_light} />
        <span :if={@show_labels}><%= @label_light %></span>
      </div>
    </.button>
    """
  end

  @doc """
  Javascript to manage switching color schemes with `color_scheme_switcher/1`.

  > #### Note: {: .info}
  >
  > This needs to be added in the page's head before `app.js` to prevent FOUC:

  ```heex
  <head>
    <.color_scheme_switcher_js />
    <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
  </head>
  ```
  """
  def color_scheme_switcher_js(assigns) do
    ~H"""
    <script>
      window.applyScheme = function (scheme) {
      if (scheme === 'light') {
      localStorage.scheme = 'light'
      document.documentElement.classList.remove('dark')
      document
        .querySelectorAll('.color-scheme-system-icon')
        .forEach((el) => el.classList.remove('hidden'))
      document
        .querySelectorAll('.color-scheme-dark-icon')
        .forEach((el) => el.classList.add('hidden'))
      document
        .querySelectorAll('.color-scheme-light-icon')
        .forEach((el) => el.classList.add('hidden'))
      } else if (scheme === 'dark') {
      localStorage.scheme = 'dark'
      document.documentElement.classList.add('dark')
      document
        .querySelectorAll('.color-scheme-system-icon')
        .forEach((el) => el.classList.add('hidden'))
      document
        .querySelectorAll('.color-scheme-dark-icon')
        .forEach((el) => el.classList.add('hidden'))
      document
        .querySelectorAll('.color-scheme-light-icon')
        .forEach((el) => el.classList.remove('hidden'))
      } else {
      localStorage.scheme = 'system'
      if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
        document.documentElement.classList.add('dark')
      } else {
        document.documentElement.classList.remove('dark')
      }
      document
        .querySelectorAll('.color-scheme-system-icon')
        .forEach((el) => el.classList.add('hidden'))
      document
        .querySelectorAll('.color-scheme-dark-icon')
        .forEach((el) => el.classList.remove('hidden'))
      document
        .querySelectorAll('.color-scheme-light-icon')
        .forEach((el) => el.classList.add('hidden'))
      }
      }

      // Scheme change events
      window
      .matchMedia('(prefers-color-scheme: dark)')
      .addEventListener('change', (_) => {
      if (localStorage.scheme === 'system') {
        applyScheme('system')
      }
      })

      window.onstorage = () => {
      applyScheme(localStorage.scheme)
      }

      // Toggle scheme
      window.toggleScheme = function () {
      if (localStorage.scheme === 'system') {
      applyScheme('dark')
      } else if (localStorage.scheme === 'dark') {
      applyScheme('light')
      } else {
      applyScheme('system')
      }
      }

      // Initialize scheme
      window.initScheme = function (scheme) {
      if (scheme === undefined) {
      scheme = localStorage.scheme || 'system'
      }
      applyScheme(scheme)
      }

      try {
      initScheme()
      } catch (_) {}
    </script>
    """
  end

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :id, :string, required: true
  attr :value, :string, required: true, doc: "text to copy"
  attr :label, :string, default: nil, doc: "button label, defaults to value"
  attr :disabled, :boolean, default: false

  attr :icon_name, :string,
    default: nil,
    doc: "the name of the icon to display (nil for none); see `icon/1` for details"

  attr :ttl, :integer,
    overridable: true,
    required: true,
    doc: "how long to show the flash message after copying"

  attr :color, :string, overridable: true, required: true, doc: "the color of the button"
  attr :shape, :string, overridable: true, required: true, doc: "shape of the button"
  attr :size, :string, overridable: true, required: true, doc: "the size of the button"
  attr :variant, :string, overridable: true, required: true, doc: "style of button"

  attr :message, :string,
    overridable: true,
    required: true,
    doc: "message to display after copying"

  attr :class, :css_classes, overridable: true
  attr :icon_class, :css_classes, overridable: true
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
      <.icon :if={@icon_name} overrides={@overrides} name={@icon_name} class={@icon_class} />
      <%= @label || @value %>
    </button>
    """
  end

  @doc """
  Generates a generic error message.
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc

  attr :icon_name, :string,
    overridable: true,
    required: true,
    doc: "the name of the icon; see `icon/1` for details"

  attr :class, :css_classes, overridable: true
  attr :icon_class, :css_classes, overridable: true

  slot :inner_block, required: true

  def error(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <p class={@class}>
      <.icon overrides={@overrides} name={@icon_name} class={@icon_class} />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display."

  attr :autoshow, :boolean,
    overridable: true,
    required: true,
    doc: "whether to auto show the flash on mount"

  attr :close, :boolean, overridable: true, required: true, doc: "whether the flash can be closed"
  attr :close_icon_name, :string, overridable: true, required: true
  attr :icon_name, :string, overridable: true, required: true
  attr :hide_js, :any, overridable: true, required: true
  attr :show_js, :any, overridable: true, required: true
  attr :title, :string, overridable: true
  attr :ttl, :integer, overridable: true, required: true
  attr :kind, :string, overridable: true, required: true, doc: "used for styling and flash lookup"

  attr :style_for_kind, :string,
    overridable: true,
    doc: "used for styling a flash with a different kind"

  attr :class, :css_classes, overridable: true
  attr :control_class, :css_classes, overridable: true
  attr :close_button_class, :css_classes, overridable: true
  attr :close_icon_class, :css_classes, overridable: true
  attr :message_class, :css_classes, overridable: true
  attr :progress_class, :css_classes, overridable: true
  attr :title_class, :css_classes, overridable: true
  attr :title_icon_class, :css_classes, overridable: true
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block to render the flash message"

  def flash(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={"phx-flash-#{@kind}"}
      phx-hook="PyroFlashComponent"
      phx-click={
        @close &&
          apply(@hide_js, [JS.push("lv:clear-flash", value: %{key: @kind}), "#phx-flash-#{@kind}"])
      }
      data-show-exec-js={apply(@show_js, [%JS{}, "#phx-flash-#{@kind}"])}
      data-autoshow={@autoshow}
      data-ttl={@ttl}
      data-hide-exec-js={
        apply(@hide_js, [JS.push("lv:clear-flash", value: %{key: @kind}), "#phx-flash-#{@kind}"])
      }
      role="alert"
      class={@class}
      {@rest}
    >
      <section :if={@ttl > 0 || @close} class={@control_class}>
        <.progress
          :if={@ttl > 0}
          overrides={@overrides}
          value={@ttl}
          max={@ttl}
          color={@kind}
          class={@progress_class}
          size="xs"
        />
        <div :if={@ttl <= 0} />
        <button :if={@close} type="button" class={@close_button_class} aria-label={gettext("close")}>
          <.icon overrides={@overrides} name={@close_icon_name} class={@close_icon_class} />
        </button>
      </section>
      <p :if={@title} class={@title_class}>
        <.icon :if={@icon_name} overrides={@overrides} name={@icon_name} class={@title_icon_class} />
        <%= @title %>
      </p>
      <p id={"phx-flash-#{@kind}-message"} class={@message_class}><%= msg %></p>
    </div>
    """
  end

  @doc """
  Shows the flash group with titles and content.

  ## Examples
      <.flash_group flash={@flash} />
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :flash, :map, required: true, doc: "the map of flash messages to display"

  attr :include_kinds, :list,
    overridable: true,
    required: true,
    doc: "the kinds of flashes to display"

  attr :class, :css_classes, overridable: true
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash tray"

  def flash_group(assigns) do
    assigns = assign_overridables(assigns)
    assigns = assign(assigns, :flash, filter_flash(assigns[:flash], assigns[:include_kinds]))

    ~H"""
    <div :if={any_flash?(@flash)} overrides={@overrides} class={@class}>
      <.flash :for={{kind, _message} <- @flash} overrides={@overrides} {parse_flash(@flash, kind)} />
    </div>
    """
  end

  # defp filter_flash(nil, _kinds), do: %{}
  defp filter_flash(_flash, nil), do: %{}

  defp filter_flash(flash, kinds) do
    flash
    |> Enum.filter(fn {kind, _msg} ->
      kind in kinds
    end)
    |> Map.new()
  end

  defp any_flash?(flash), do: !Enum.empty?(Map.keys(flash))

  defp parse_flash(flash, kind) do
    flash
    |> Phoenix.Flash.get(kind)
    |> Jason.decode()
    |> case do
      {:ok, %{"message" => message} = parsed} ->
        Enum.reduce(parsed, [flash: Map.put(%{}, kind, message), kind: kind], fn
          {"message", _}, acc ->
            acc

          {_key, nil}, acc ->
            acc

          {"icon_name", value}, acc ->
            Keyword.put(acc, :icon_name, value)

          {"ttl", value}, acc ->
            Keyword.put(acc, :ttl, value)

          {"title", value}, acc ->
            Keyword.put(acc, :title, value)

          {"close", value}, acc ->
            Keyword.put(acc, :close, value)

          {"style_for_kind", value}, acc ->
            Keyword.put(acc, :style_for_kind, value)
        end)

      _ ->
        [flash: Map.put(%{}, kind, Map.get(flash, kind)), kind: kind]
    end
  end

  @doc """
  Renders a header with title and optional subtitle/actions.
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :class, :css_classes, overridable: true
  attr :title_class, :css_classes, overridable: true
  attr :subtitle_class, :css_classes, overridable: true
  attr :actions_class, :css_classes, overridable: true
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <header class={@class}>
      <div>
        <h1 class={@title_class}>
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class={@subtitle_class}>
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div :if={@actions != []} class={@actions_class}>
        <%= render_slot(@actions) %>
      </div>
    </header>
    """
  end

  @doc """
  Renders an icon.

  > #### Tip {: .info}
  >
  > See the [Heroicons website](https://heroicons.com/) to preview/search the available icons.

  Additionally, there are long-term plans to add more icon libraries.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc

  attr :name, :string,
    required: true,
    doc: "the icon name"

  attr :class, :css_classes, overridable: true

  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  def icon(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc

  attr :autofocus, :boolean,
    default: false,
    doc: "enable autofocus hook to reliably focus input on mount"

  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :description, :string, default: nil
  attr :errors, :list, default: []

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :id, :any, default: nil

  attr :label, :string, default: nil
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :name, :any
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"

  attr :type, :string,
    default: "text",
    values:
      ~w[checkbox color date datetime-local email file hidden month number password range radio search select tel text textarea time url week datetime-zoned]

  attr :value, :any

  attr :clear_on_escape, :boolean,
    overridable: true,
    required: true,
    doc: "clear input value on pressing Escape"

  attr :tz, :string, default: "Etc/UTC", doc: "timezone"

  attr :get_tz_options, :any,
    overridable: true,
    required: true,
    doc: "a 0 arity function that returns a list of valid timezones"

  attr :tz_options, :list, default: nil

  attr :class, :css_classes,
    overridable: true,
    doc: "class of the field container element"

  attr :input_class, :css_classes,
    overridable: true,
    doc: "class of the input element"

  attr :input_check_label_class, :css_classes,
    overridable: true,
    doc: "class of the label element for a check input"

  attr :input_datetime_zoned_wrapper_class, :css_classes,
    overridable: true,
    doc: "class of the input wrapper element for a datetime zoned input"

  attr :description_class, :css_classes,
    overridable: true,
    doc: "class of the field description"

  attr :rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                                 pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(assigns) do
    assigns
    |> assign_overridables()
    |> render_input()
  end

  defp render_input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div class={@class} phx-feedback-for={@name}>
      <label class={@input_check_label_class}>
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={@input_class}
          phx-mounted={!@autofocus || JS.focus()}
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors} overrides={@overrides}><%= msg %></.error>
    </div>
    """
  end

  defp render_input(%{type: "datetime-zoned", tz_options: nil, get_tz_options: get_tz_options} = assigns) do
    render_input(assign(assigns, :tz_options, apply(get_tz_options, [])))
  end

  defp render_input(%{type: "datetime-zoned"} = assigns) do
    assigns = assign_date_time_timezone_value(assigns)

    ~H"""
    <div phx-feedback-for={@name} class={@class}>
      <.label for={@id} overrides={@overrides}><%= @label %></.label>
      <div class={@input_datetime_zoned_wrapper_class}>
        <input
          type="datetime-local"
          id={@id}
          class={@input_class}
          name={@name <> "[date_time]"}
          value={@date_time_value}
          step="1"
          phx-keydown={!@clear_on_escape || JS.dispatch("pyro:clear")}
          phx-key={!@clear_on_escape || "Escape"}
          phx-mounted={!@autofocus || JS.focus()}
        />
        <input
          type="search"
          id={@id <> "_time_zone"}
          class={@input_class}
          name={@name <> "[time_zone]"}
          value={@timezone_value}
          list={@id <> "_time_zone_list"}
          phx-keydown={!@clear_on_escape || JS.dispatch("pyro:clear")}
          phx-key={!@clear_on_escape || "Escape"}
        />
        <datalist id={@id <> "_time_zone_list"}>
          <option :for={z <- @tz_options} value={z} />
        </datalist>
      </div>
      <%= render_slot(@inner_block) %>
      <p :if={@description} class={@description_class}>
        <%= @description %>
      </p>
      <.error :for={msg <- @errors} overrides={@overrides}><%= msg %></.error>
    </div>
    """
  end

  defp render_input(%{type: "select"} = assigns) do
    ~H"""
    <div class={@class} phx-feedback-for={@name}>
      <.label for={@id} overrides={@overrides}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class={@input_class}
        multiple={@multiple}
        phx-mounted={!@autofocus || JS.focus()}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <%= render_slot(@inner_block) %>
      <p :if={@description} class={@description_class}>
        <%= @description %>
      </p>
      <.error :for={msg <- @errors} overrides={@overrides}><%= msg %></.error>
    </div>
    """
  end

  defp render_input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@class}>
      <.label for={@id} overrides={@overrides}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={@input_class}
        phx-keydown={!@clear_on_escape || JS.dispatch("pyro:clear")}
        phx-key={!@clear_on_escape || "Escape"}
        phx-mounted={!@autofocus || JS.focus()}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <%= render_slot(@inner_block) %>
      <p :if={@description} class={@description_class}>
        <%= @description %>
      </p>
      <.error :for={msg <- @errors} overrides={@overrides}><%= msg %></.error>
    </div>
    """
  end

  defp render_input(%{type: "hidden"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@class}>
      <.label for={@id} overrides={@overrides}><%= @label %></.label>
      <input
        type="hidden"
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        {@rest}
      />
      <%= render_slot(@inner_block) %>
      <p :if={@description} class={@description_class}>
        <%= @description %>
      </p>
      <.error :for={msg <- @errors} overrides={@overrides}><%= msg %></.error>
    </div>
    """
  end

  defp render_input(assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@class}>
      <.label for={@id} overrides={@overrides}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={@input_class}
        phx-keydown={!@clear_on_escape || JS.dispatch("pyro:clear")}
        phx-key={!@clear_on_escape || "Escape"}
        phx-mounted={!@autofocus || JS.focus()}
        {@rest}
      />
      <%= render_slot(@inner_block) %>
      <p :if={@description} class={@description_class}>
        <%= @description %>
      </p>
      <.error :for={msg <- @errors} overrides={@overrides}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :for, :string, default: nil
  attr :class, :css_classes, overridable: true
  slot :inner_block, required: true

  def label(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <label for={@for} class={@class}>
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Renders a description list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :class, :css_classes, overridable: true
  attr :dd_class, :css_classes, overridable: true
  attr :dt_class, :css_classes, overridable: true

  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <dl class={@class}>
      <%= for item <- @item do %>
        <dt class={@dt_class}><%= item.title %></dt>
        <dd class={@dd_class}><%= render_slot(item) %></dd>
      <% end %>
    </dl>
    """
  end

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        Are you sure?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>

  JS commands may be passed to the `:on_cancel` and `on_confirm` attributes
  for the caller to react to each button press, for example:

      <.modal id="confirm" on_confirm={JS.push("delete")} on_cancel={JS.navigate(~p"/posts")}>
        Are you sure you?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}
  attr :show_js, :any, overridable: true, required: true
  attr :hide_js, :any, overridable: true, required: true
  attr :class, :css_classes, overridable: true
  slot :inner_block, required: true
  slot :title
  slot :subtitle
  slot :confirm
  slot :cancel

  def modal(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <div
      id={@id}
      phx-mounted={@show && apply(@show_js, [%JS{}, @id])}
      phx-remove={apply(@hide_js, [%JS{}, @id])}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class={@class}
    >
      <div id={"#{@id}-bg"} class="fixed inset-0 bg-zinc-50/90 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <header :if={@title != []}>
                  <h1 id={"#{@id}-title"} class={@header_title_class}>
                    <%= render_slot(@title) %>
                  </h1>
                  <p
                    :if={@subtitle != []}
                    id={"#{@id}-description"}
                    class="mt-2 text-sm leading-6 text-zinc-600"
                  >
                    <%= render_slot(@subtitle) %>
                  </p>
                </header>
                <%= render_slot(@inner_block) %>
                <div :if={@confirm != [] or @cancel != []} class="ml-6 mb-4 flex items-center gap-5">
                  <.button
                    :for={confirm <- @confirm}
                    overrides={@overrides}
                    id={"#{@id}-confirm"}
                    phx-click={@on_confirm}
                    phx-disable-with
                    class="py-2 px-3"
                  >
                    <%= render_slot(confirm) %>
                  </.button>
                  <.link
                    :for={cancel <- @cancel}
                    phx-click={apply(@hide_js, [@on_cancel, @id])}
                    class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                  >
                    <%= render_slot(cancel) %>
                  </.link>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a navigation link, taking into account whether the URI is the current page.
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :label, :string, required: true, doc: "the label of of the link"
  attr :uri, :string, required: true, doc: "the URI of the link"
  attr :current_uri, :string, required: true, doc: "the current URI of the page"
  attr :class, :css_classes, overridable: true, doc: "the class of the navigation link"

  def nav_link(assigns) do
    %{path: current_path} = URI.parse(assigns[:current_uri])
    %{path: path} = URI.parse(assigns[:uri])

    assigns =
      assigns
      |> assign(:is_current?, current_path == path)
      |> assign_overridables()

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

  attr :class, :css_classes,
    overridable: true,
    doc: "the class of the progress bar"

  attr :rest, :global

  def progress(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <progress value={@value} max={@max} class={@class} {@rest} />
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :class, :css_classes, overridable: true
  attr :actions_class, :css_classes, overridable: true

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <.form :let={f} for={@for} as={@as} class={@class} {@rest}>
      <%= render_slot(@inner_block, f) %>
      <section :for={action <- @actions} class={@actions_class}>
        <%= render_slot(action, f) %>
      </section>
    </.form>
    """
  end

  @doc """
  A slide-over component.

  ## Example

      <%= if @slide_over do %>
        <.slide_over origin={@slide_over} max_width="sm" title="Slide Over">
          <p>
            This is a slide over.
          </p>
        </.slide_over>
      <% end %>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :close_icon_name, :string, overridable: true, required: true

  attr :title, :string, doc: "the title of the slide-over"

  attr :id, :string, default: "slide-over"
  attr :origin, :string, overridable: true, required: true
  attr :max_width, :string, overridable: true, required: true

  attr :hide_js, :any, overridable: true, required: true

  attr :close_even_name, :string,
    default: "close_slide_over",
    doc: "the name of the event to send when the slide-over is closed"

  attr :close_slide_over_target, :string,
    default: nil,
    doc: "the specific live component to target for the close event, e.g. close_slide_over_target={@myself}"

  attr :class, :css_classes, overridable: true
  attr :overlay_class, :css_classes, overridable: true
  attr :wrapper_class, :css_classes, overridable: true
  attr :header_class, :css_classes, overridable: true
  attr :header_inner_class, :css_classes, overridable: true
  attr :header_title_class, :css_classes, overridable: true
  attr :header_close_button_class, :css_classes, overridable: true
  attr :content_class, :css_classes, overridable: true
  attr :close_icon_class, :css_classes, overridable: true

  attr :rest, :global
  slot :inner_block, required: true

  def slide_over(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <div id={@id} {@rest}>
      <div id={"#{@id}-overlay"} class={@overlay_class} aria-hidden="true"></div>

      <div class={@wrapper_class} role="dialog" aria-modal="true">
        <div
          id={"#{@id}-content"}
          class={@class}
          phx-click-away={
            apply(@hide_js, [%JS{}, @id, @origin, @close_even_name, @close_slide_over_target])
          }
          phx-window-keydown={
            apply(@hide_js, [%JS{}, @id, @origin, @close_even_name, @close_slide_over_target])
          }
          phx-key="escape"
        >
          <%!-- Header --%>
          <div class={@header_class}>
            <div class={@header_inner_class}>
              <div class={@header_title_class}>
                <%= @title %>
              </div>

              <button
                phx-click={
                  apply(@hide_js, [%JS{}, @id, @origin, @close_even_name, @close_slide_over_target])
                }
                class={@header_close_button_class}
              >
                <div class="sr-only">Close</div>
                <.icon class={@close_icon_class} name={@close_icon_name} />
              </button>
            </div>
          </div>
          <%!-- Content --%>
          <div class={@content_class}>
            <%= render_slot(@inner_block) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  A simple spinner component.
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :show, :boolean, default: true, doc: "show or hide spinner"
  attr :rest, :global
  attr :size, :string, overridable: true, required: true, doc: "the size of the spinner"
  attr :class, :css_classes, overridable: true

  def spinner(assigns) do
    assigns = assign_overridables(assigns)

    ~H"""
    <svg {@rest} class={@class} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
      <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
      <path
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      />
    </svg>
    """
  end

  @doc ~S"""
  Renders a simple table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """

  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
  attr :id, :string
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_id, :any,
    default: nil,
    doc: "the function for generating the row id"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  attr :rows, :list, required: true

  attr :class, :css_classes, overridable: true
  attr :action_class, :css_classes, overridable: true
  attr :action_td_class, :css_classes, overridable: true
  attr :action_wrapper_class, :css_classes, overridable: true
  attr :tbody_class, :css_classes, overridable: true
  attr :td_class, :css_classes, overridable: true
  attr :th_action_class, :css_classes, overridable: true
  attr :th_label_class, :css_classes, overridable: true
  attr :thead_class, :css_classes, overridable: true
  attr :tr_class, :css_classes, overridable: true

  slot :col, required: true do
    attr :label, :string
  end

  slot(:action, doc: "the slot for showing user actions in the last table column")

  def table(assigns) do
    assigns = assign_overridables(assigns)

    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class={@class}>
      <thead class={@thead_class}>
        <tr>
          <th :for={col <- @col} class={@th_label_class}><%= col[:label] %></th>
          <th class={@th_action_class}><span class="sr-only"><%= gettext("Actions") %></span></th>
        </tr>
      </thead>
      <tbody
        id={@id}
        class={@tbody_class}
        phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
      >
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class={@tr_class}>
          <td :for={col <- @col} phx-click={@row_click && @row_click.(row)} class={@td_class}>
            <%= render_slot(col, @row_item.(row)) %>
          </td>
          <td :if={@action != []} class={@action_td_class}>
            <div class={@action_wrapper_class}>
              <span :for={action <- @action} class={@action_class}>
                <%= render_slot(action, @row_item.(row)) %>
              </span>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
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

  attr :icon_name, :string,
    overridable: true,
    required: true,
    doc: "the name of the icon; see `icon/1` for details"

  attr :class, :css_classes, overridable: true
  attr :tooltip_class, :css_classes, overridable: true
  attr :tooltip_text_class, :css_classes, overridable: true
  attr :icon_class, :css_classes, overridable: true

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
        <.icon overrides={@overrides} name={@icon_name} class={@icon_class} />
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

  defp assign_date_time_timezone_value(assigns) do
    tz = assigns[:tz]

    case assigns[:value] do
      nil ->
        assigns
        |> assign(:date_time_value, "")
        |> assign(:timezone_value, tz)

      %{"date_time" => date_time, "time_zone" => time_zone} ->
        assigns
        |> assign(:date_time_value, date_time)
        |> assign(:timezone_value, time_zone)

      date_time ->
        case DateTime.shift_zone(date_time, tz) do
          {:ok, shifted} ->
            year = shifted.year |> Integer.to_string() |> String.pad_leading(4, "0")
            month = shifted.month |> Integer.to_string() |> String.pad_leading(2, "0")
            day = shifted.day |> Integer.to_string() |> String.pad_leading(2, "0")
            hour = shifted.hour |> Integer.to_string() |> String.pad_leading(2, "0")
            minute = shifted.minute |> Integer.to_string() |> String.pad_leading(2, "0")

            assigns
            |> assign(:date_time_value, "#{year}-#{month}-#{day}T#{hour}:#{minute}")
            |> assign(:timezone_value, tz)

          _ ->
            assigns
            |> assign(:date_time_value, "")
            |> assign(:timezone_value, tz)
        end
    end
  end
end
