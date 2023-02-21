defmodule Phlegethon.Overrides.Default do
  @moduledoc """
  This is the default configuration for Phlegethon components.

  If you provide no other configuration, this is what Phlegethon will use by default. You will likely want to merge it with your own custom overrides, see `Phlegethon.Overrides` for instructions on how to do that.

  It can be helpful to view the source of this override configuration to get an idea of how to write your own overrides.
  """

  use Phlegethon.Overrides,
    makeup_light: &Makeup.Styles.HTML.StyleMap.autumn_style/0,
    makeup_dark: &Makeup.Styles.HTML.StyleMap.monokai_style/0,
    extend_colors: %{
      "root" => "#ffffff",
      "root-dark" => "#0c0c0f",
      "root-fg" => "#0c0c0f",
      "root-fg-dark" => "#ffffff",
      "root-2" => "#e5e7eb",
      "root-2-dark" => "#2e303d",
      "root-3" => "#f3f4f6",
      "root-3-dark" => "#46495d",
      "brand-1" => "#ff914d",
      "brand-2" => "#ffbd59",
      "brand-3" => "#ff5757"
    },
    global_style: """
    @layer root {
      /* Firefox */
      * {
        scrollbar-width: thin;
        scrollbar-color: theme(colors.brand-1) transparent;
      }

      /* Chrome, Edge, and Safari */
      *::-webkit-scrollbar {
        @apply w-1;
      }

      *::-webkit-scrollbar-track {
        background: transparent;
      }

      *::-webkit-scrollbar-thumb {
        @apply border-none bg-brand-1 rounded;
      }

      var {
        @apply not-italic rounded font-mono text-sm font-semibold px-2 py-px mx-px;
        @apply bg-root-fg text-root;
        @apply dark:bg-root-fg-dark dark:text-root-dark;
      }
    }

    @layer component {
      .progress {
        @apply appearance-none rounded;
      }
      .progress::-webkit-progress-value {
        @apply rounded;
      }
      .progress.error::-webkit-progress-bar {
        @apply bg-red-600;
      }
      .progress.error::-webkit-progress-value {
        @apply bg-red-400;
      }
      .progress.warning::-webkit-progress-bar {
        @apply bg-yellow-600;
      }
      .progress.warning::-webkit-progress-value {
        @apply bg-yellow-400;
      }
      .progress.success::-webkit-progress-bar {
        @apply bg-green-600;
      }
      .progress.success::-webkit-progress-value {
        @apply bg-green-400;
      }
      .progress.info::-webkit-progress-bar {
        @apply bg-root;
      }
      .progress.info::-webkit-progress-value {
        @apply bg-root-fg;
      }
      .dark .progress.info::-webkit-progress-bar {
        @apply bg-root-dark;
      }
      .dark .progress.info::-webkit-progress-value {
        @apply bg-root-fg-dark;
      }
      .progress::-moz-progress-bar {
        /* TODO: style rules for FF */
      }
    }
    """

  ##############################################################################
  ####    C O R E    C O M P O N E N T S
  ##############################################################################

  override Core, :alert do
    set :class, &__MODULE__.alert_class/1
    set :color, "info"
    set :colors, ~w[info success warning danger]
  end

  def alert_class(assigns) do
    color = assigns[:color]

    [
      "block",
      "p-2",
      "rounded",
      "bg-sky-200 text-black": color == "info",
      "bg-green-400 text-black": color == "success",
      "bg-yellow-400 text-black": color == "warning",
      "bg-red-400 text-white": color == "danger"
    ]
  end

  override Core, :back do
    set :class, "text-sm font-semibold hover:text-brand-3"
    set :icon_class, "w-3 h-3 stroke-current align-baseline"
    set :icon_kind, :solid
    set :icon_name, :chevron_left
  end

  override Core, :button do
    set :class, &__MODULE__.button_class/1
    set :colors, ~w[root primary red yellow green]
    set :color, "primary"
    set :size, "base"
    set :sizes, ~w[xs sm base lg xl]
    set :outline, false
    set :shadow, false
    set :pill, false
    set :shadow_hover, false
    set :shadow_focus, false
  end

  def button_class(assigns) do
    size = assigns[:size]
    pill = assigns[:pill]
    color = assigns[:color]
    outline = assigns[:outline]
    shadow = assigns[:shadow]
    shadow_hover = assigns[:shadow_hover]
    shadow_focus = assigns[:shadow_focus]

    [
      "font-black",
      "uppercase",
      "text-center",
      "inline-block",
      "cursor-pointer",
      "disabled:cursor-not-allowed",
      "disabled:opacity-50",
      "appearance-none",
      "select-none",
      "px-2",
      "whitespace-nowrap",
      "hover:scale-105",
      "active:opacity-50",
      "text-xs": size == "xs",
      "text-sm": size == "sm",
      "text-base": size == "base",
      "text-lg": size == "lg",
      "text-xl": size == "xl",
      "rounded-full": pill,
      "rounded-sm": !pill && size == "xs",
      rounded: !pill && size == "base",
      rounded: !pill && size == "lg",
      rounded: !pill && size == "xl",
      "rounded-sm": !pill && size == "sm",
      "border border-solid": outline,
      "border-2": outline && size == "base",
      "border-2": outline && size == "lg",
      "border-2": outline && size == "xl",
      "shadow-lg": shadow,
      "hover:shadow-lg": shadow_hover,
      "focus:shadow-lg": shadow_focus,
      "shadow-root dark:shadow-root-fg-dark":
        (shadow || shadow_hover || shadow_focus) && color == "root",
      "shadow-brand-1 dark:shadow-brand-3":
        (shadow || shadow_hover || shadow_focus) && color == "primary",
      "shadow-red-400": (shadow || shadow_hover || shadow_focus) && color == "red",
      "shadow-yellow-400": (shadow || shadow_hover || shadow_focus) && color == "yellow",
      "shadow-green-400": (shadow || shadow_hover || shadow_focus) && color == "green",
      "bg-brand-1 dark:bg-brand-3": color == "primary" && !outline,
      "text-brand-1 dark:text-brand-3 border-brand-1 dark:border-brand-3":
        color == "primary" && outline,
      "bg-root-fg dark:bg-root-fg-dark text-root dark:text-root-dark":
        color == "root" && !outline,
      "text-root-fg dark:text-root-fg-dark border-root-fg dark:border-root-fg-dark":
        color == "root" && outline,
      "bg-red-500 text-white": color == "red" && !outline,
      "text-red-500 border-red-500": color == "red" && outline,
      "bg-green-500 text-white": color == "green" && !outline,
      "text-green-500 border-green-500": color == "green" && outline,
      "bg-yellow-400 text-black": color == "yellow" && !outline,
      "text-yellow-400 border-yellow-400": color == "yellow" && outline
    ]
  end

  override Core, :error do
    set :class, "phx-no-feedback:hidden flex gap-3 text-sm text-red-500"
    set :icon_name, :exclamation_circle
    set :icon_kind, :mini
    set :icon_class, "mt-0.5 h-5 w-5 flex-none fill-red-500"
  end

  @flash_kinds ~w[info error warning success]

  override Core, :flash do
    set :autoshow, true
    set :class, &__MODULE__.flash_class/1
    set :close, true
    set :close_button_class, "absolute top-2 right-1 p-2"
    set :close_icon_class, "h-5 w-5 stroke-current opacity-40 group-hover:opacity-70"
    set :close_icon_name, :x_mark
    set :icon_kind, :mini
    set :icon_name, &__MODULE__.flash_icon_name/1
    set :style_for_kind, &__MODULE__.flash_style_for_kind/1
    set :kind, "info"
    set :kinds, @flash_kinds
    set :message_class, "text-sm whitespace-pre-wrap"
    set :progress_class, "absolute top-1 left-0 w-full h-1"
    set :title, &__MODULE__.flash_title/1
    set :title_class, "flex items-center gap-1.5 text-sm font-semibold leading-6"
    set :ttl, 10_000
    set :show_js, &__MODULE__.flash_show_js/2
    set :hide_js, &__MODULE__.flash_hide_js/2
  end

  def flash_title(assigns) do
    case assigns[:kind] do
      "info" -> "Information"
      "error" -> "Error"
      "warning" -> "Warning"
      "success" -> "Success"
      _ -> nil
    end
  end

  def flash_icon_name(assigns) do
    case assigns[:kind] do
      "info" -> :information_circle
      "error" -> :exclamation_circle
      "warning" -> :exclamation_triangle
      "success" -> :check_circle
      _ -> :information_circle
    end
  end

  def flash_style_for_kind(assigns) do
    assigns[:kind]
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

  def flash_class(assigns) do
    kind = assigns[:kind]
    style_for_kind = assigns[:style_for_kind]
    close = assigns[:close]

    [
      "hidden w-80 sm:w-96 rounded p-3 shadow-md shadow-zinc-900/5 group relative z-10",
      [
        "cursor-pointer": close,
        "bg-red-500 text-white": kind == "error" || style_for_kind == "error",
        "bg-yellow-500 text-black": kind == "warning" || style_for_kind == "warning",
        "bg-green-500 text-black": kind == "success" || style_for_kind == "success",
        "bg-root text-root-fg dark:bg-root-dark dark:text-root-fg-dark ring-1 ring-root-fg dark:ring-root-fg-dark":
          kind == "info" || style_for_kind == "info" ||
            (style_for_kind not in @flash_kinds and kind not in @flash_kinds)
      ]
    ]
  end

  override Core, :flash_group do
    set :class, "absolute top-2 right-2 grid gap-2"
    set :include_kinds, @flash_kinds
  end

  override Core, :header do
    set :class, &__MODULE__.header_class/1
    set :title_class, &__MODULE__.header_title_class/1
    set :subtitle_class, "mt-2 text-lg font-semibold text uppercase text-brand-3"
    set :actions_class, "no-flex"
  end

  def header_class(assigns) do
    actions = assigns[:actions]

    ["flex items-center justify-between gap-6": actions != []]
  end

  def header_title_class(assigns) do
    actions = assigns[:actions]

    ["leading-normal font-bold text-5xl text-brand-2", ["text-center": actions == []]]
  end

  override Core, :input do
    set :class, "grid gap-1 content-start"
    set :input_class, &__MODULE__.input_class/1
    set :description_class, "text-xs"
    set :clear_on_escape, true
  end

  def input_class(assigns) do
    type = assigns[:type]

    errors? =
      case assigns[:errors] do
        [] -> false
        [_ | _] -> true
      end

    [
      "block",
      "w-full",
      "rounded",
      "border",
      "border-solid",
      "focus:ring-4",
      "bg-root dark:bg-root-dark",
      "text-root-fg dark:text-root-fg-dark",
      [
        "border-root-fg dark:border-root-fg-dark": !errors?,
        "border-red-500 focus:border-red-500 focus:ring-red-500": errors?,
        "focus:ring-brand-1": !errors?,
        # "": type == "text",
        "min-h-[6rem]": type == "textarea"
      ]
    ]
  end

  override Core, :label do
    set :class, "block text-sm font-black text-root-fg dark:text-root-fg-dark"
  end

  override Core, :simple_form do
    set :class, "grid gap-2"
    set :actions_class, "mt-2 flex items-center justify-between gap-6"
  end

  override Core, :list do
    set :class, "-my-4 divide-y divide-zinc-100"
    set :wrapper_class, "flex gap-4 py-4 sm:gap-8"
    set :dt_class, "w-1/4 flex-none text-[0.8125rem] leading-6 text-zinc-500"
    set :dd_class, "text-sm leading-6 text-zinc-700"
  end

  override Core, :modal do
    set :class, "relative z-50 hidden"
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
    set :class, "w-full"
    set :thead_class, "text-left text-[0.8125rem] leading-6"
    set :th_label_class, "p-0 pb-4 pr-6 font-normal"
    set :th_action_class, "relative p-0 pb-4"

    set :tbody_class,
        "relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 "

    set :tr_class, "relative group hover:bg-zinc-50"
    set :td_class, &__MODULE__.table_td_class/1
    set :action_td_class, "p-0 w-14"
    set :action_wrapper_class, "relative whitespace-nowrap py-4 text-right text-sm font-medium"
    set :action_class, "relative ml-4 font-semibold leading-6 hover:text-zinc-700"
  end

  def table_td_class(assigns) do
    row_click = assigns[:row_click]
    ["p-0", ["hover:cursor-pointer": row_click]]
  end

  ##############################################################################
  ####    P H L E G E T H O N    C O M P O N E N T S
  ##############################################################################

  override Icon, :icon do
    set :class, "h-4 w-4 inline-block align-text-bottom"
    set :kind, :solid
  end

  override Extra, :code do
    set :class,
        "makeup whitespace-pre-wrap p-4 rounded bg-root-2 dark:bg-root-2-dark shadow"
  end

  @progress_colors ~w[info error warning success]
  override Extra, :progress do
    set :class, &__MODULE__.progress_class/1
    set :size, "base"
    set :sizes, ~w[xs sm base lg xl]
    set :color, "info"
    set :colors, @progress_colors
  end

  def progress_class(assigns) do
    color = assigns[:color]
    size = assigns[:size]

    [
      "progress",
      [
        "h-1": size == "xs",
        "h-2": size == "sm",
        "h-4": size == "base",
        "h-6": size == "lg",
        "h-8": size == "xl",
        error: color == "error",
        warning: color == "warning",
        success: color == "success",
        info: color == "info" || color not in @progress_colors
      ]
    ]
  end

  ##############################################################################
  ####    S M A R T    C O M P O N E N T S
  ##############################################################################

  override SmartForm, :smart_form do
    set :action_info, &__MODULE__.smart_form_action_info/1
    set :autocomplete, "off"
    set :actions_class, "mt-2 flex items-center justify-between gap-6"
    set :class, &__MODULE__.smart_form_class/1
    set :phlegethon_form, &__MODULE__.smart_form_phlegethon_form/1
  end

  def smart_form_class(assigns) do
    [
      "grid gap-2",
      get_by_path(assigns, [:phlegethon_form, :class])
    ]
  end

  def smart_form_phlegethon_form(assigns) do
    UI.form_for(assigns[:resource], assigns[:action])
  end

  def smart_form_action_info(assigns) do
    UI.action(assigns[:resource], assigns[:action])
  end

  override SmartForm, :render_field do
    set :field_group_class, &__MODULE__.smart_form_field_group_class/1
    set :field_group_label_class, "font-black col-span-full"
    set :attribute, &__MODULE__.smart_form_field_attribute/1
  end

  def smart_form_field_group_class(assigns) do
    [
      "grid col-span-full gap-2 p-2 border border-solid rounded",
      get_by_path(assigns, [:field, :class])
    ]
  end

  def smart_form_field_attribute(%{
        resource: resource,
        field: %Phlegethon.Resource.Form.Field{name: name}
      }) do
    UI.attribute(resource, name)
  end

  def smart_form_field_attribute(_assigns), do: nil
end
