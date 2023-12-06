defmodule Pyro.Overrides.Default do
  # credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
  @moduledoc """
  This is the default style configuration for Pyro components.

  It can be helpful to view the source of this override configuration to get an idea of how to write your own style overrides.
  """

  ##############################################################################
  ####    S T Y L E    S E T T I N G S
  ##############################################################################

  @variant_colors ~w[slate gray zinc neutral stone red orange amber yellow lime green emerald teal cyan sky blue indigo violet purple fuchsia pink rose]
  @invariant_colors ~w[transparent white black]
  @all_colors @variant_colors ++ @invariant_colors
  @flash_kinds ~w[info error warning success] ++ @variant_colors

  use Pyro.Overrides

  defp color_class(color) do
    case color do
      "slate" -> "pyro--slate"
      "gray" -> "pyro--gray"
      "zinc" -> "pyro--zinc"
      "neutral" -> "pyro--neutral"
      "stone" -> "pyro--stone"
      "red" -> "pyro--red"
      "orange" -> "pyro--orange"
      "amber" -> "pyro--amber"
      "yellow" -> "pyro--yellow"
      "lime" -> "pyro--lime"
      "green" -> "pyro--green"
      "emerald" -> "pyro--emerald"
      "teal" -> "pyro--teal"
      "cyan" -> "pyro--cyan"
      "sky" -> "pyro--sky"
      "blue" -> "pyro--blue"
      "indigo" -> "pyro--indigo"
      "violet" -> "pyro--violet"
      "purple" -> "pyro--purple"
      "fuchsia" -> "pyro--fuchsia"
      "pink" -> "pyro--pink"
      "rose" -> "pyro--rose"
      "transparent" -> "pyro--transparent"
      "white" -> "pyro--white"
      "black" -> "pyro--black"
    end
  end

  defp size_class(size) do
    case size do
      "xs" -> "pyro--xs"
      "sm" -> "pyro--sm"
      "md" -> "pyro--md"
      "lg" -> "pyro--lg"
      "xl" -> "pyro--xl"
    end
  end

  ##############################################################################
  ####    C O R E    C O M P O N E N T S
  ##############################################################################

  override Core, :back do
    set :class, "pyro-back"
    set :icon_class, "pyro-back__icon"
    set :icon_name, "hero-chevron-left-solid"
  end

  override Core, :button do
    set :class, &__MODULE__.button_class/1
    set :ping_class, "pyro-btn__ping"
    set :icon_class, "pyro-btn__icon"
    set :colors, @all_colors
    set :color, "sky"
    set :variant, "solid"
    set :variants, ~w[solid inverted outline]
    set :shape, "rounded"
    set :shapes, ~w[rounded square pill]
    set :size, "md"
    set :sizes, ~w[xs sm md lg xl]
    set :case, "uppercase"
  end

  def button_class(passed_assigns) do
    variant =
      case passed_assigns[:variant] do
        "solid" -> "pyro-btn--solid"
        "inverted" -> "pyro-btn--inverted"
        "outline" -> "pyro-btn--outline"
      end

    shape =
      case passed_assigns[:shape] do
        "rounded" -> "pyro-btn--rounded"
        "square" -> "pyro-btn--square"
        "pill" -> "pyro-btn--pill"
      end

    [
      "pyro-btn",
      size_class(passed_assigns[:size]),
      color_class(passed_assigns[:color]),
      shape,
      variant,
      passed_assigns[:case]
    ]
  end

  override Core, :error do
    set :class, "pyro-error"
    set :icon_name, "hero-exclamation-circle-mini"
    set :icon_class, "pyro-error__icon"
  end

  override Core, :flash do
    set :class, &__MODULE__.flash_class/1
    set :control_class, "pyro-flash__control"
    set :close_icon_class, "pyro-flash__close_icon"
    set :close_icon_name, "hero-x-mark-mini"
    set :icon_name, &__MODULE__.flash_icon_name/1
    set :kind, "slate"
    set :kinds, @flash_kinds
    set :message_class, "pyro-flash__message"
    set :progress_class, "pyro-flash__progress"
    set :title, &__MODULE__.flash_title/1
    set :title_class, "pyro-flash__title"
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

  def flash_class(passed_assigns) do
    kind = passed_assigns[:kind]
    style_for_kind = passed_assigns[:style_for_kind]
    close = passed_assigns[:close]
    ttl = passed_assigns[:ttl]

    color =
      cond do
        style_for_kind in @variant_colors ->
          style_for_kind

        kind in @variant_colors ->
          kind

        true ->
          case kind do
            "success" -> "green"
            "warning" -> "yellow"
            "error" -> "red"
            "info" -> "sky"
            _ -> "slate"
          end
      end

    [
      "pyro-flash",
      color_class(color),
      "pt-1": close || ttl > 0,
      "cursor-pointer": close
    ]
  end

  def flash_show_js(js, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def flash_hide_js(js, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  override Core, :flash_group do
    set :class, "pyro-flash_group"
    set :include_kinds, @flash_kinds
  end

  override Core, :header do
    set :class, &__MODULE__.header_class/1
    set :title_class, "pyro-header__title"
    set :subtitle_class, "pyro-header__subtitle"
    set :actions_class, "pyro-header__actions"
  end

  def header_class(passed_assigns) do
    ["pyro-header", "pyro--actions": passed_assigns[:actions] != []]
  end

  override Core, :icon do
    set :class, "pyro-icon"
  end

  override Core, :input do
    set :class, "pyro-input"
    set :input_class, &__MODULE__.input_class/1
    set :input_check_label_class, "pyro-input__input_check_label"
    set :description_class, "pyro-input__description"
    set :clear_on_escape, true
  end

  def input_class(passed_assigns) do
    ["pyro-input__input", "pyro--errors": passed_assigns[:errors] != []]
  end

  override Core, :label do
    set :class, "pyro-label"
  end

  override Core, :simple_form do
    set :class, "pyro-simple_form"
    set :actions_class, "pyro-simple_form__actions"
  end

  override Core, :list do
    set :class, "pyro-list"
    set :dt_class, "pyro-list__dt"
    set :dd_class, "pyro-list__dd"
  end

  override Core, :modal do
    set :class, "pyro-modal"
    set :show_js, &__MODULE__.modal_show_js/2
    set :hide_js, &__MODULE__.modal_hide_js/2
  end

  def modal_show_js(js, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def modal_hide_js(js, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  override Core, :table do
    set :class, "pyro-table"
    set :thead_class, "pyro-table__thead"
    set :th_label_class, "pyro-table__th_label"
    set :th_action_class, "pyro-table__th_action"
    set :tbody_class, "pyro-table__tbody"
    set :tr_class, "pyro-table__tr"
    set :td_class, &__MODULE__.table_td_class/1
    set :action_td_class, "pyro-table__action_td"
    set :action_wrapper_class, "pyro-table__action_wrapper"
    set :action_class, "pyro-table__action"
  end

  def table_td_class(passed_assigns) do
    ["pyro-table__td", "hover:cursor-pointer": passed_assigns[:row_click]]
  end

  override Core, :a do
    set :class, "pyro-a"
    set :replace, false
  end

  override Core, :code do
    set :class, "makeup pyro-code"
    set :copy_class, "pyro-code__copy"
    set :copy, true
    set :copy_label, "Copy"
  end

  override Core, :copy_to_clipboard do
    set :class, &__MODULE__.button_class/1
    set :icon_class, "pyro-btn__icon"
    set :colors, @all_colors
    set :color, "sky"
    set :variant, "solid"
    set :variants, ~w[solid inverted outline]
    set :shape, "rounded"
    set :shapes, ~w[rounded square pill]
    set :size, "md"
    set :sizes, ~w[xs sm md lg xl]
    set :case, "uppercase"
    set :message, "Copied! 📋"
    set :ttl, 3_000
  end

  override Core, :nav_link do
    set :class, &__MODULE__.nav_link_class/1
    set :is_current, &__MODULE__.nav_link_is_current/1
  end

  @doc """
  Determine if the current path prop matches the uri prop.

  This is useful for styling the link differently if the link is "active".
  """
  def nav_link_is_current(passed_assigns) do
    %{path: current_path} = URI.parse(passed_assigns[:current_uri])
    %{path: path} = URI.parse(passed_assigns[:uri])
    current_path == path
  end

  def nav_link_class(passed_assigns) do
    ["pyro-nav_link", current: passed_assigns[:is_current]]
  end

  override Core, :progress do
    set :class, &__MODULE__.progress_class/1
    set :size, "md"
    set :sizes, ~w[xs sm md lg xl]
    set :color, "sky"
    set :colors, @variant_colors
  end

  def progress_class(passed_assigns) do
    color =
      case passed_assigns[:color] do
        "error" -> "red"
        "info" -> "sky"
        "warning" -> "yellow"
        "success" -> "green"
        color -> color
      end

    ["pyro-progress", color_class(color), size_class(passed_assigns[:size])]
  end

  override Core, :spinner do
    set :class, &__MODULE__.spinner_class/1
    set :size, "md"
    set :sizes, ~w[xs sm md lg xl]
  end

  def spinner_class(passed_assigns) do
    ["pyro-spinner", size_class(passed_assigns[:size]), hidden: !passed_assigns[:show]]
  end

  override Core, :tooltip do
    set :class, "pyro-tooltip"
    set :tooltip_class, "pyro-tooltip__tooltip"
    set :tooltip_text_class, "pyro-tooltip__text"
    set :icon_name, "hero-question-mark-circle-solid"
    set :vertical_offset, "2.25rem"
    set :horizontal_offset, "0"
  end

  @theme :system

  override Extra, :color_theme_switcher do
    set :class, &__MODULE__.color_theme_switcher_class/1
    set :theme, &__MODULE__.color_theme_switcher_theme/1
    set :label_system, "System"
    set :label_light, "Light"
    set :label_dark, "Dark"
    set :icon_system, "hero-computer-desktop-mini"
    set :icon_light, "hero-sun-solid"
    set :icon_dark, "hero-moon-solid"
  end

  def color_theme_switcher_class(passed_assigns) do
    ["whitespace-nowrap", passed_assigns[:class], "color-theme-switcher"]
  end

  def color_theme_switcher_theme(passed_assigns) do
    passed_assigns[:theme] || @theme
  end

  ##############################################################################
  ####    L I V E    C O M P O N E N T S
  ##############################################################################

  override Autocomplete, :render do
    set :class, "pyro-autocomplete"
    set :input_class, &__MODULE__.input_class/1
    set :description_class, "pyro-input__description"
    set :throttle_time, 212
    set :option_label_key, :label
    set :option_value_key, :id
    set :prompt, "Search options"
    set :listbox_class, "pyro-autocomplete__listbox"
    set :listbox_option_class, &__MODULE__.autocomplete_listbox_option_class/1
  end

  def autocomplete_listbox_option_class(passed_assigns) do
    ["pyro-autocomplete__listbox_option", "pyro--results": passed_assigns[:results] != []]
  end

  ##############################################################################
  ####    S M A R T    C O M P O N E N T S
  ##############################################################################

  override SmartForm, :smart_form do
    set :class, &__MODULE__.smart_form_class/1
    set :actions_class, "pyro-smart_form__actions"
    set :autocomplete, "off"
  end

  def smart_form_class(passed_assigns) do
    ["pyro-smart_form", passed_assigns.pyro_form.class || nil]
  end

  override SmartForm, :render_field do
    set :field_group_class, &__MODULE__.smart_form_field_group_class/1
    set :field_group_label_class, "pyro-smart_form__render_field__group_label"
  end

  def smart_form_field_group_class(passed_assigns) do
    ["pyro-smart_form__render_field__group", passed_assigns.field.class || nil]
  end

  # override SmartDataTable, :render do
  #   set :class, "grid"
  #   set :pyro_table, &__MODULE__.smart_data_table_pyro_table/1
  # end

  # def smart_data_table_pyro_table(passed_assigns) do
  #   UI.table_for(passed_assigns[:resource])
  # end
end
