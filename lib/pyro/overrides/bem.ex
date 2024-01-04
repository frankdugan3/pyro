defmodule Pyro.Overrides.BEM do
  # credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
  @moduledoc """
  This overrides file adds [BEM](https://getbem.com/) classes to all Pyro components. It does not define any style.

  This is great if you want to fully customize your own styles; all you have to do is define the classes in your CSS file.

  ## Configuration

  As with any Pyro overrides, you need to include the override file in your `config.exs` file:

  ```elixir
  config :pyro, :overrides, [Pyro.Overrides.BEM]
  ```

  Then, just implement the component classes listed in [Overrides](#module-overrides) in your CSS file.

  In addition to the component classes, Pyro also expects the following utility classes to be implemented:

  ```css
  .hidden {
    display: none;
  }
  ```

  You can override specific settings by merging in your own overrides file, as described [here](`Pyro.Overrides`). Additionally, the BEM overrides file supports a few application config options:

  ```elixir
  # Prefix applied to all BEM classes, useful for namespacing Pyro's components in a brownfield project.
  # Defaults to `""`
  config :pyro, :bem_prefix, "pyro-"

  # Specify color variants. Defaults to all Tailwind colors families.
  config :pyro, :bem_color_variants, ["red", "green", "brand"]

  # Specify flash variants. Defaults to `~w[info error warning success]`
  config :pyro, :bem_flash_variants, ["danger", "warning"]

  # Specify size variants. Defaults to `~w[xs sm md lg xl]`
  config :pyro, :bem_size_variants, ["normal", "huge"]

  # Specify button variants. Defaults to `~w[solid inverted outline]`
  config :pyro, :bem_size_variants, ["normal", "ghost"]

  # Specify button shape variants. Defaults to `~w[rounded square pill]`
  config :pyro, :bem_size_variants, ["normal", "obtuse"]
  ```

  ## Using with Tailwind

  The classes are built dynamically, so if you want to use Tailwind, you will need to implement your styles *without* the layer directive to ensure they are always included, and you will need to ensure you put them before the utilities import for correct precedence:

  ```css
  @tailwind base;
  @tailwind components;

  /* This will always be included in your compiled CSS */
  .button {
    /* ... */
  }

  @tailwind utilities;
  ```

  Also, be sure to remove any Pyro-related files from your `content` list in `tailwind.config.js`, otherwise you will be including unused classes from other override themes.
  """

  ##############################################################################
  ####    S T Y L E    S E T T I N G S
  ##############################################################################

  use Pyro.Overrides

  import Pyro.Component.Helpers, only: [get_nested: 2]

  @prefix Application.compile_env(:pyro, :bem_prefix, "")
  @color_variants Application.compile_env(
                    :pyro,
                    :bem_color_variants,
                    ~w[slate gray zinc neutral stone red orange amber yellow lime green emerald teal cyan sky blue indigo violet purple fuchsia pink rose]
                  )
  @flash_variants Application.compile_env(
                    :pyro,
                    :bem_flash_variants,
                    ~w[info error warning success]
                  )
  @size_variants Application.compile_env(:pyro, :bem_size_variants, ~w[xs sm md lg xl])
  @button_variants Application.compile_env(
                     :pyro,
                     :bem_button_variants,
                     ~w[solid inverted outline]
                   )
  @button_shapes Application.compile_env(:pyro, :bem_button_shapes, ~w[rounded square pill])

  ##############################################################################
  ####    C O R E    C O M P O N E N T S
  ##############################################################################

  override Core, :a do
    set :class, @prefix <> "a"
    set :replace, false
  end

  @prefixed_back @prefix <> "back"
  override Core, :back do
    set :class, @prefixed_back
    set :icon_class, @prefixed_back <> "__icon"
    set :icon_name, "hero-chevron-left-solid"
  end

  @prefixed_button @prefix <> "button"
  @button_icon_class @prefixed_button <> "__icon"
  override Core, :button do
    set :class, &__MODULE__.button_class/1
    set :ping_class, @prefixed_button <> "__ping"
    set :ping_animation_class, @prefixed_button <> "__ping_animation"
    set :icon_class, @button_icon_class
    set :colors, @color_variants
    set :color, "sky"
    set :variant, "solid"
    set :variants, @button_variants
    set :shape, "rounded"
    set :shapes, @button_shapes
    set :size, "md"
    set :sizes, @size_variants
  end

  def button_class(passed_assigns) do
    [
      @prefixed_button,
      @prefixed_button <> "--" <> passed_assigns[:size],
      @prefixed_button <> "--" <> passed_assigns[:color],
      @prefixed_button <> "--" <> passed_assigns[:shape],
      @prefixed_button <> "--" <> passed_assigns[:variant]
    ]
  end

  @prefixed_code @prefix <> "code"
  override Core, :code do
    set :class, @prefixed_code <> " makeup"
    set :copy_class, @prefixed_code <> "__copy"
    set :copy, true
    set :copy_label, "Copy"
  end

  override Core, :color_scheme_switcher do
    set :class, @prefix <> "color_scheme_switcher"
    set :scheme, &__MODULE__.color_scheme_switcher_scheme/1
    set :label_system, "System"
    set :label_light, "Light"
    set :label_dark, "Dark"
    set :icon_system, "hero-computer-desktop-mini"
    set :icon_light, "hero-sun-solid"
    set :icon_dark, "hero-moon-solid"
  end

  def color_scheme_switcher_scheme(passed_assigns) do
    passed_assigns[:scheme] || :system
  end

  override Core, :copy_to_clipboard do
    set :class, &__MODULE__.button_class/1
    set :icon_class, @button_icon_class
    set :colors, @color_variants
    set :color, "sky"
    set :variant, "solid"
    set :variants, @button_variants
    set :shape, "rounded"
    set :shapes, @button_shapes
    set :size, "md"
    set :sizes, @size_variants
    set :message, "Copied! 📋"
    set :ttl, 3_000
  end

  @prefixed_error @prefix <> "error"
  override Core, :error do
    set :class, @prefixed_error
    set :icon_class, @prefixed_error <> "__icon"
    set :icon_name, "hero-exclamation-circle-mini"
  end

  @prefixed_flash @prefix <> "flash"
  override Core, :flash do
    set :class, @prefixed_flash
    set :control_class, @prefixed_flash <> "__control"
    set :close_button_class, @prefixed_flash <> "__close_button"
    set :close_icon_class, @prefixed_flash <> "__close_icon"
    set :message_class, @prefixed_flash <> "__message"
    set :progress_class, @prefixed_flash <> "__progress"
    set :title_class, @prefixed_flash <> "__title"
    set :title__icon_class, @prefixed_flash <> "__title_icon"
    set :icon_name, &__MODULE__.flash_icon_name/1
    set :close_icon_name, "hero-x-mark-mini"
    set :kind, "info"
    set :kinds, @flash_variants
    set :title, &__MODULE__.flash_title/1
    set :autoshow, true
    set :close, true
    set :ttl, 10_000
    set :show_js, &__MODULE__.flash_show_js/2
    set :hide_js, &__MODULE__.flash_hide_js/2
  end

  def flash_title(passed_assigns) do
    case passed_assigns[:kind] do
      "info" -> "Information"
      "error" -> "Error"
      "warning" -> "Warning"
      "success" -> "Success"
      _ -> nil
    end
  end

  def flash_icon_name(passed_assigns) do
    case passed_assigns[:kind] do
      "info" -> "hero-information-circle-mini"
      "error" -> "hero-exclamation-circle-mini"
      "warning" -> "hero-exclamation-triangle-mini"
      "success" -> "hero-check-circle-mini"
      _ -> "hero-bell-mini"
    end
  end

  def flash_show_js(js, selector) do
    JS.show(js, to: selector)
  end

  def flash_hide_js(js, selector) do
    JS.hide(js, to: selector)
  end

  override Core, :flash_group do
    set :class, @prefix <> "flash_group"
    set :include_kinds, @flash_variants
  end

  @prefixed_header @prefix <> "header"
  override Core, :header do
    set :class, @prefixed_header
    set :title_class, @prefixed_header <> "__title"
    set :subtitle_class, @prefixed_header <> "__subtitle"
    set :actions_class, @prefixed_header <> "__actions"
  end

  override Core, :icon do
    set :class, @prefix <> "icon"
  end

  @prefixed_input @prefix <> "input"
  override Core, :input do
    set :class, @prefixed_input
    set :input_class, &__MODULE__.input_class/1
    set :input_check_label_class, @prefixed_input <> "__input_check_label"
    set :input_datetime_zoned_wrapper_class, @prefixed_input <> "__input_datetime_zoned_wrapper"
    set :description_class, @prefixed_input <> "__description"
    set :clear_on_escape, true
    set :get_tz_options, &Pyro.Component.Helpers.all_timezones/0
  end

  def input_class(passed_assigns) do
    [@prefixed_input <> "__input", "has-errors": passed_assigns[:errors] != []]
  end

  override Core, :label do
    set :class, @prefix <> "label"
  end

  @prefixed_list @prefix <> "list"
  override Core, :list do
    set :class, @prefixed_list
    set :dt_class, @prefixed_list <> "__dt"
    set :dd_class, @prefixed_list <> "__dd"
  end

  override Core, :modal do
    set :class, @prefix <> "modal"
    # TODO: Add other classes
    set :show_js, &__MODULE__.modal_show_js/2
    set :hide_js, &__MODULE__.modal_hide_js/2
  end

  # TODO: Add animation classes, document at top.
  def modal_show_js(js, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(to: "##{id}-bg")
    |> JS.show(to: "##{id}-container")
    |> JS.focus_first(to: "##{id}-content")
  end

  def modal_hide_js(js, id) do
    js
    |> JS.hide(to: "##{id}-bg")
    |> JS.hide(to: "##{id}-container")
    |> JS.hide(to: "##{id}")
    |> JS.pop_focus()
  end

  @prefixed_nav_link @prefix <> "nav_link"
  override Core, :nav_link do
    set :class, &__MODULE__.nav_link_class/1
  end

  def nav_link_class(passed_assigns) do
    [@prefixed_nav_link, {:"#{@prefixed_nav_link}--current", passed_assigns[:is_current]}]
  end

  @prefixed_progress @prefix <> "progress"
  override Core, :progress do
    set :class, &__MODULE__.progress_class/1
    set :size, "md"
    set :sizes, @size_variants
    set :color, "sky"
    set :colors, @color_variants
  end

  def progress_class(passed_assigns) do
    case_result =
      case passed_assigns[:color] do
        "error" -> "red"
        "info" -> "sky"
        "warning" -> "yellow"
        "success" -> "green"
        color -> color
      end

    color =
      then(case_result, &(@prefixed_progress <> "--" <> &1))

    size = @prefixed_progress <> "--" <> passed_assigns[:size]

    [@prefixed_progress, color, size]
  end

  @prefixed_simple_form @prefix <> "simple_form"
  override Core, :simple_form do
    set :class, @prefixed_simple_form
    set :actions_class, @prefixed_simple_form <> "__actions"
  end

  @prefixed_slide_over @prefix <> "slide_over"
  override Core, :slide_over do
    set :class, @prefixed_slide_over
    set :overlay_class, @prefixed_slide_over <> "__overlay"
    set :wrapper_class, @prefixed_slide_over <> "__wrapper"
    set :header_class, @prefixed_slide_over <> "__header"
    set :header_inner_class, @prefixed_slide_over <> "__header_inner"
    set :header_title_class, @prefixed_slide_over <> "__header_title"
    set :header_close_button_class, @prefixed_slide_over <> "__header_close_button"
    set :content_class, @prefixed_slide_over <> "__content"
    set :close_icon_class, @prefixed_slide_over <> "__close_icon"
    set :close_icon_name, "hero-x-mark-solid"
    set :origin, "left"
    set :origins, ~w[left right top bottom]
    set :max_width, "md"
    set :max_widths, ~w[sm md lg xl 2xl full]
    set :hide_js, &__MODULE__.slide_over_hide_js/5
  end

  def slide_over_hide_js(js, id, _origin, close_event_name, close_slide_over_target) do
    js =
      js
      |> JS.hide(to: "##{id}-overlay")
      |> JS.hide(to: "##{id}-content")

    if close_slide_over_target do
      JS.push(js, close_event_name, close_slide_over_target)
    else
      JS.push(js, close_event_name)
    end
  end

  @prefixed_spinner @prefix <> "spinner"
  override Core, :spinner do
    set :class, &__MODULE__.spinner_class/1
    set :size, "md"
    set :sizes, @size_variants
  end

  def spinner_class(passed_assigns) do
    [
      @prefixed_spinner,
      @prefixed_spinner <> "--" <> passed_assigns[:size],
      hidden: !passed_assigns[:show]
    ]
  end

  @prefixed_table @prefix <> "table"
  override Core, :table do
    set :class, @prefixed_table
    set :thead_class, @prefixed_table <> "__thead"
    set :th_label_class, @prefixed_table <> "__th_label"
    set :th_action_class, @prefixed_table <> "__th_action"
    set :tbody_class, @prefixed_table <> "__tbody"
    set :tr_class, @prefixed_table <> "__tr"
    set :td_class, @prefixed_table <> "__td"
    set :action_td_class, @prefixed_table <> "__action_td"
    set :action_wrapper_class, @prefixed_table <> "__action_wrapper"
    set :action_class, @prefixed_table <> "__action"
  end

  @prefixed_tooltip @prefix <> "tooltip"
  override Core, :tooltip do
    set :class, @prefixed_tooltip
    set :tooltip_class, @prefixed_tooltip <> "__tooltip"
    set :tooltip_text_class, @prefixed_tooltip <> "__text"
    set :icon_name, "hero-question-mark-circle-solid"
    set :vertical_offset, "2.25rem"
    set :horizontal_offset, "0"
  end

  ##############################################################################
  ####    D A T A    T A B L E    C O M P O N E N T
  ##############################################################################

  @prefixed_data_table @prefix <> "data_table"
  override Pyro.Components.DataTable, :data_table do
    set :class, @prefixed_data_table
    set :header_class, @prefixed_data_table <> "__header"
    set :body_class, @prefixed_data_table <> "__body"
    set :row_class, @prefixed_data_table <> "__row"
    set :footer_class, @prefixed_data_table <> "__footer"
  end

  @prefixed_data_table_sort @prefix <> "data_table_sort"
  override Pyro.Components.DataTable, :sort do
    set :class, @prefixed_data_table_sort
    set :btn_class, @prefixed_data_table_sort <> "__btn"
  end

  @prefixed_data_table_cell @prefix <> "data_table_cell"
  override Pyro.Components.DataTable, :cell do
    set :class, @prefixed_data_table_cell
  end

  @prefixed_data_table_sort_icon @prefix <> "data_table_sort_icon"
  override Pyro.Components.DataTable, :sort_icon do
    set :class, @prefixed_data_table_sort_icon
    set :index_class, @prefixed_data_table_sort_icon <> "__index"
  end

  ##############################################################################
  ####    L I V E    C O M P O N E N T S
  ##############################################################################

  @prefixed_autocomplete @prefix <> "autocomplete"
  override Autocomplete, :render do
    set :class, @prefixed_autocomplete
    set :input_class, &__MODULE__.input_class/1
    set :description_class, @prefixed_input <> "__description"
    set :listbox_class, @prefixed_autocomplete <> "__listbox"
    set :listbox_option_class, @prefixed_autocomplete <> "__listbox_option"
    set :throttle_time, 212
    set :option_label_key, :label
    set :option_value_key, :id
    set :prompt, "Search options"
  end

  if Code.ensure_loaded?(AshPhoenix) do
    ##############################################################################
    ####    S M A R T    C O M P O N E N T S
    ##############################################################################

    @prefixed_smart_data_table @prefix <> "smart_data_table"
    override SmartDataTable, :smart_data_table do
      set :class, &__MODULE__.smart_data_table_class/1
    end

    def smart_data_table_class(passed_assigns) do
      [@prefixed_smart_data_table, get_nested(passed_assigns, [:pyro_data_table, :class])]
    end

    @prefixed_smart_form @prefix <> "smart_form"
    override SmartForm, :smart_form do
      set :class, &__MODULE__.smart_form_class/1
      set :actions_class, @prefixed_smart_form <> "__actions"
      set :autocomplete, "off"
    end

    def smart_form_class(passed_assigns) do
      [@prefixed_smart_form, get_nested(passed_assigns, [:pyro_form, :class])]
    end

    @prefixed_smart_form_render_field @prefix <> "smart_form_render_field"
    override SmartForm, :render_field do
      set :field_group_class, &__MODULE__.smart_form_field_group_class/1
      set :field_group_label_class, @prefixed_smart_form_render_field("__group_label")
    end

    def smart_form_field_group_class(passed_assigns) do
      [
        @prefixed_smart_form_render_field <> "__group",
        get_nested(passed_assigns, [:field, :class])
      ]
    end
  end
end
