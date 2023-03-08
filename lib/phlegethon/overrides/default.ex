defmodule Phlegethon.Overrides.Default do
  @moduledoc """
  This is the default style configuration for Phlegethon components.

  It can be helpful to view the source of this override configuration to get an idea of how to write your own style overrides.
  """

  ##############################################################################
  ####    S T Y L E    S E T T I N G S
  ##############################################################################

  @theme_colors ~w[root brand info error warning success]
  @bg_gradient "dark:bg-gradient-to-tr dark:from-zinc-900 dark:to-zinc-800"
  @root_theme "bg-white text-zinc-900  dark:text-white #{@bg_gradient}"
  @shared_link_class "font-black border-b-2 border-dotted text-zinc-900 border-zinc-900 dark:text-white dark:border-white hover:text-brand hover:border-brand active:text-brand active:border-brand active:border-solid"
  @shared_shadow_class "shadow-md shadow-zinc-900/5 dark:shadow-zinc-300/5"

  use Phlegethon.Overrides,
    makeup_light: &Makeup.Styles.HTML.StyleMap.autumn_style/0,
    makeup_dark: &Makeup.Styles.HTML.StyleMap.monokai_style/0,
    # https://mycolor.space/?hex=%23442165&sub=1
    extend_colors: %{
      "brand" => "#FD4F00",
      "brand-fg" => "#FFFFFF"
    },
    global_style: """
    @layer root {
      /* Firefox */
      * {
        scrollbar-width: thin;
        scrollbar-color: theme(colors.brand) transparent;
      }

      /* Chrome, Edge, and Safari */
      *::-webkit-scrollbar {
        @apply w-1;
      }

      *::-webkit-scrollbar-track {
        background: transparent;
      }

      *::-webkit-scrollbar-thumb {
        @apply border-none bg-brand rounded;
      }

      var {
        @apply not-italic rounded font-mono text-sm font-semibold px-2 py-px mx-px;
        @apply bg-zinc-900 text-white;
        @apply dark:bg-white dark:text-zinc-900;
      }

      html, body {
        @apply #{@root_theme};
      }
    }

    @layer component {
      .progress {
        @apply rounded w-full
      }
      .progress::-webkit-progress-bar {
        @apply rounded;
      }
      .progress::-webkit-progress-value {
        @apply rounded;
      }
      .progress::-moz-progress-bar {
        @apply rounded;
      }
      .progress,
      .progress::-webkit-progress-bar {
        @apply bg-zinc-100 dark:bg-zinc-900;
      }
      .progress::-webkit-progress-value {
        @apply bg-zinc-900 dark:bg-zinc-600;
      }
      .progress::-moz-progress-bar {
        @apply bg-zinc-900 dark:bg-zinc-600;
      }
      .progress.brand,
      .progress.brand::-webkit-progress-bar {
        @apply bg-orange-100 dark:bg-orange-900;
      }
      .progress.brand::-webkit-progress-value {
        @apply bg-brand;
      }
      .progress.brand::-moz-progress-bar {
        @apply bg-brand;
      }
      .progress.info,
      .progress.info::-webkit-progress-bar {
        @apply bg-cyan-100 dark:bg-cyan-900;
      }
      .progress.info::-webkit-progress-value {
        @apply bg-cyan-500;
      }
      .progress.info::-moz-progress-bar {
        @apply bg-cyan-500;
      }
      .progress.error,
      .progress.error::-webkit-progress-bar {
        @apply bg-rose-100 dark:bg-rose-900;
      }
      .progress.error::-webkit-progress-value {
        @apply bg-rose-500;
      }
      .progress.error::-moz-progress-bar {
        @apply bg-rose-500;
      }
      .progress.warning,
      .progress.warning::-webkit-progress-bar {
        @apply bg-yellow-100 dark:bg-yellow-900;
      }
      .progress.warning::-webkit-progress-value {
        @apply bg-yellow-400;
      }
      .progress.warning::-moz-progress-bar {
        @apply bg-yellow-400;
      }
      .progress.success,
      .progress.success::-webkit-progress-bar {
        @apply bg-emerald-100 dark:bg-emerald-900;
      }
      .progress.success::-webkit-progress-value {
        @apply bg-emerald-500;
      }
      .progress.success::-moz-progress-bar {
        @apply bg-emerald-500;
      }
    }
    """

  ##############################################################################
  ####    C O R E    C O M P O N E N T S
  ##############################################################################

  override Core, :back do
    set :class, @shared_link_class
    set :icon_class, "w-3 h-3 stroke-current align-baseline"
  end

  override Core, :button do
    set :class, &__MODULE__.button_class/1
    set :ping_class, &__MODULE__.button_ping_class/1
    set :icon_class, &__MODULE__.button_icon_class/1
    set :colors, @theme_colors
    set :color, "brand"
  end

  def button_class(assigns) do
    size = assigns[:size]
    variant = assigns[:variant]
    shape = assigns[:shape]
    color = assigns[:color]
    disabled = assigns[:disabled]

    [
      assigns[:case],
      @shared_shadow_class,
      "font-semibold",
      "text-center",
      "inline-block",
      "cursor-pointer",
      "disabled:cursor-not-allowed",
      "disabled:opacity-50",
      "appearance-none",
      "select-none",
      "px-2",
      "whitespace-nowrap",
      "active:opacity-50",
      "relative",
      "hover:scale-105": !disabled,
      "text-xs": size == "xs",
      "text-sm": size == "sm",
      "text-base": size == "md",
      "text-lg": size == "lg",
      "text-xl": size == "xl",
      rounded: shape == "rounded",
      "rounded-full": shape == "pill",
      "border border-solid": variant in ["outline", "inverted"],
      "border-2": variant in ["outline", "inverted"] && size == "md",
      "border-2": variant in ["outline", "inverted"] && size == "lg",
      "border-2": variant in ["outline", "inverted"] && size == "xl",
      "bg-zinc-900 text-white dark:bg-white dark:text-zinc-900":
        color == "root" && variant == "solid",
      "bg-brand text-brand-fg": color == "brand" && variant == "solid",
      "bg-cyan-500 text-cyan-900": color == "info" && variant == "solid",
      "bg-rose-500 text-rose-100": color == "error" && variant == "solid",
      "bg-yellow-500 text-yellow-900": color == "warning" && variant == "solid",
      "bg-emerald-500 text-emerald-900": color == "success" && variant == "solid",
      "border-zinc-900 text-zinc-900 dark:border-white dark:text-white hover:bg-zinc-900 hover:text-white dark:hover:bg-white dark:hover:text-zinc-900":
        color == "root" && variant == "inverted",
      "border-brand text-brand bg-brand-fg hover:bg-brand hover:text-brand-fg":
        color == "brand" && variant == "inverted",
      "border-cyan-500 text-cyan-500 bg-cyan-900 hover:bg-cyan-500 hover:text-cyan-900":
        color == "info" && variant == "inverted",
      "border-rose-500 text-rose-500 bg-rose-100 hover:bg-rose-500 hover:text-rose-100":
        color == "error" && variant == "inverted",
      "border-yellow-500 text-yellow-500 bg-yellow-900 hover:bg-yellow-500 hover:text-yellow-900":
        color == "warning" && variant == "inverted",
      "border-emerald-500 text-emerald-500 bg-emerald-900 hover:bg-emerald-500 hover:text-emerald-900":
        color == "success" && variant == "inverted",
      "border-zinc-900 text-zinc-900 dark:border-white dark:text-white":
        color == "root" && variant == "outline",
      "border-brand text-brand": color == "brand" && variant == "outline",
      "border-cyan-500 text-cyan-500": color == "info" && variant == "outline",
      "border-rose-500 text-rose-500": color == "error" && variant == "outline",
      "border-yellow-500 text-yellow-500": color == "warning" && variant == "outline",
      "border-emerald-500 text-emerald-500": color == "success" && variant == "outline"
    ]
  end

  def button_ping_class(assigns) do
    shape = assigns[:shape]

    [
      "block",
      "absolute",
      "rounded-full",
      "w-3",
      "h-3",
      "bg-rose-500",
      "-top-1.5 -right-1.5": shape != "pill",
      "-top-1 -right-1": shape == "pill"
    ]
  end

  def button_icon_class(assigns) do
    size = assigns[:size]

    [
      "h-5 w-5": size in ["md", "lg"],
      "h-6 w-6": size == "xl"
    ]
  end

  override Core, :error do
    set :class,
        "phx-no-feedback:hidden flex gap-1 text-sm leading-6 text-rose-600 dark:text-rose-500"

    set :icon_name, "hero-exclamation-circle-mini"
    set :icon_class, "h-5 w-5 flex-none inline"
  end

  override Core, :flash do
    set :class, &__MODULE__.flash_class/1
    set :control_class, "grid grid-cols-[1fr,auto] items-center gap-1"
    set :close_icon_class, "h-5 w-5 stroke-current opacity-40 group-hover:opacity-70 block -mr-2"
    set :close_icon_name, "hero-x-mark-mini"
    set :icon_name, &__MODULE__.flash_icon_name/1
    set :kind, "info"
    set :kinds, @theme_colors
    set :message_class, "text-sm whitespace-pre-wrap"
    set :progress_class, "border border-black/25"
    set :title, &__MODULE__.flash_title/1
    set :title_class, "flex items-center gap-1.5 text-sm font-semibold leading-6"
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
      "info" -> "hero-information-circle-mini"
      "error" -> "hero-exclamation-circle-mini"
      "warning" -> "hero-exclamation-triangle-mini"
      "success" -> "hero-check-circle-mini"
      _ -> "hero-bell-mini"
    end
  end

  def flash_class(assigns) do
    kind = assigns[:kind]
    style_for_kind = assigns[:style_for_kind]
    close = assigns[:close]
    ttl = assigns[:ttl]

    [
      "hidden w-80 sm:w-96 rounded p-3 group relative z-50 ring-1",
      @shared_shadow_class,
      "pt-1": close || ttl > 0,
        "cursor-pointer": close,
      "bg-orange-100 text-orange-900 ring-brand fill-orange-900 dark:bg-orange-900 dark:text-orange-100 dark:ring-brand dark:fill-orange-100":
        kind == "brand" || style_for_kind == "brand",
      "bg-cyan-50 text-cyan-800 ring-cyan-500 fill-cyan-900 dark:bg-cyan-900 dark:text-cyan-100 dark:ring-cyan-500 dark:fill-cyan-50":
        kind == "info" || style_for_kind == "info",
      "bg-rose-50 p-3 text-rose-900 ring-rose-500 fill-rose-900 dark:bg-rose-900 dark:text-rose-100 dark:ring-rose-400 dark:fill-rose-50":
        kind == "error" || style_for_kind == "error",
      "bg-yellow-50 text-yellow-800 ring-yellow-500 fill-yellow-900 dark:bg-yellow-900 dark:text-yellow-100 dark:ring-yellow-500 dark:fill-yellow-50":
        kind == "warning" || style_for_kind == "warning",
      "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-emerald-900 dark:bg-emerald-900 dark:text-emerald-100 dark:ring-emerald-500 dark:fill-emerald-50":
        kind == "success" || style_for_kind == "success",
      "bg-zinc-50 text-zinc-800 ring-zinc-500 fill-zinc-900 dark:bg-zinc-800 dark:text-white dark:ring-zinc-600 dark:fill-zinc-100":
        kind == "root" || style_for_kind == "root" ||
          (style_for_kind not in @theme_colors and kind not in @theme_colors)
    ]
  end

  override Core, :flash_group do
    set :class, "absolute top-2 right-2 grid gap-2"
    set :include_kinds, @theme_colors
  end

  override Core, :header do
    set :class, &__MODULE__.header_class/1
    set :title_class, &__MODULE__.header_title_class/1
    set :subtitle_class, "mt-2 text-sm leading-6 text-zinc-600 dark:text-zinc-200"
    set :actions_class, "no-flex flex gap-2"
  end

  def header_class(assigns) do
    actions = assigns[:actions]

    ["flex items-center justify-between gap-6": actions != []]
  end

  def header_title_class(assigns) do
    actions = assigns[:actions]

    [
      "text-lg font-semibold leading-8 text-zinc-800 dark:text-zinc-50",
      "text-center": actions == []
    ]
  end

  override Core, :icon do
    set :class, "h-4 w-4 inline-block align-text-bottom"
    set :kind, :solid
  end

  override Core, :input do
    set :class, "grid gap-1 content-start"
    set :input_class, &__MODULE__.input_class/1
    set :input_check_label_class, "flex items-center gap-2 text-sm leading-6 text-zinc-800 dark:text-zinc-100 font-semibold"
    set :description_class, "text-xs text-zinc-600 dark:text-zinc-400"
  end

  def input_class(assigns) do
    type = assigns[:type]

    errors? =
      case assigns[:errors] do
        [] -> false
        [_ | _] -> true
      end

    [
      "rounded-lg",
      "block w-full  border-zinc-300 py-[7px] px-[11px]",
      "sm:text-sm sm:leading-6",
      "bg-transparent text-zinc-900 dark:text-white",
      "focus:outline-none focus:ring-4",
      "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400 phx-no-feedback:focus:ring-zinc-800/5",
      "border-zinc-300 dark:border-zinc-700 focus:border-zinc-500 focus:ring-zinc-800/5 dark:focus:border-zinc-50 dark:focus:ring-zinc-50/25":
        !errors?,
      "border-rose-600 focus:border-rose-600 focus:ring-rose-600/10 dark:border-rose-500 dark:focus:border-rose-500 dark:focus:ring-rose-500/25":
        errors?,
      "w-auto rounded text-brand focus:ring-brand dark:text-brand dark:focus:ring-brand": type == "checkbox",
      "py-2 px-3": type == "select",
        "min-h-[6rem]": type == "textarea"
    ]
  end

  override Core, :label do
    set :class, "block text-sm font-semibold leading-6 text-zinc-800 dark:text-zinc-100"
  end

  override Core, :simple_form do
    set :class, "grid gap-2 #{@root_theme}"
    set :actions_class, "mt-2 flex items-center justify-between gap-6"
  end

  override Core, :list do
    set :class, "grid grid-cols-[auto,1fr] gap-2"
    set :dt_class, "font-black leading-6"
    set :dd_class, ""
  end

  override Core, :modal do
    set :class, "relative z-50 hidden"
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
    ["p-0", "hover:cursor-pointer": row_click]
  end

  ##############################################################################
  ####    P H L E G E T H O N    C O M P O N E N T S
  ##############################################################################

  override Extra, :a do
    set :class, @shared_link_class
  end

  override Extra, :code do
    set :class,
        ["makeup whitespace-pre-wrap p-4 rounded", @shared_shadow_class]
  end

  override Extra, :nav_link do
    set :class, &__MODULE__.nav_link_class/1
  end

  def nav_link_class(assigns) do
    is_current = assigns[:is_current]

    [
      @shared_link_class,
      "border-solid cursor-default text-zinc-900 dark:text-white border-zinc-900 dark:border-white":
        is_current
    ]
  end

  override Extra, :progress do
    set :class, &__MODULE__.progress_class/1
    set :size, "md"
    set :sizes, ~w[xs sm md lg xl]
    set :color, "info"
    set :colors, @theme_colors
  end

  def progress_class(assigns) do
    color = assigns[:color]
    size = assigns[:size]

    [
      "progress",
        "h-1": size == "xs",
        "h-2": size == "sm",
      "h-4": size == "md",
        "h-6": size == "lg",
        "h-8": size == "xl",
      root: color == "root" || color not in @theme_colors,
      brand: color == "brand",
      info: color == "info",
        error: color == "error",
        warning: color == "warning",
      success: color == "success"
      ]
  end

  override Extra, :spinner do
    set :class, &__MODULE__.spinner_class/1
  end

  def spinner_class(assigns) do
    size = assigns[:size]
    show = assigns[:show]

    [
      "animate-spin",
      "inline-block",
      "align-baseline",
      hidden: !show,
      "h-2 w-2": size == "xs",
      "h-3 w-3": size == "sm",
      "h-3 w-3": size == "md",
      "h-3 w-3": size == "lg",
      "h-4 w-4": size == "xl"
    ]
  end

  override Extra, :tooltip do
    set :class,
        "group hover:relative inline-block select-none hover:bg-brand rounded cursor-help"

    set :tooltip_class,
        [
          "absolute invisible select-none group-hover:visible normal-case block z-10",
          @shared_shadow_class
        ]

    set :tooltip_text_class,
        "bg-brand text-brand-fg min-w-[20rem] p-2 rounded text-sm font-normal whitespace-pre"
  end

  ##############################################################################
  ####    S M A R T    C O M P O N E N T S
  ##############################################################################

  override SmartForm, :smart_form do
    set :actions_class, "mt-2 flex items-center justify-between gap-6"
    set :class, &__MODULE__.smart_form_class/1
  end

  def smart_form_class(assigns) do
    [
      "grid gap-2",
      get_by_path(assigns, [:phlegethon_form, :class])
    ]
  end

  override SmartForm, :render_field do
    set :field_group_class, &__MODULE__.smart_form_field_group_class/1
    set :field_group_label_class, "font-black col-span-full"
  end

  def smart_form_field_group_class(assigns) do
    [
      "grid col-span-full gap-2 p-2 border border-solid rounded-lg",
      "border-zinc-300 dark:border-zinc-700",
      get_by_path(assigns, [:field, :class])
    ]
  end
end
