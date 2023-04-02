defmodule Phlegethon.Overrides.Default do
  @moduledoc """
  This is the default style configuration for Phlegethon components.

  It can be helpful to view the source of this override configuration to get an idea of how to write your own style overrides.
  """

  ##############################################################################
  ####    S T Y L E    S E T T I N G S
  ##############################################################################

  @theme_colors ~w[slate gray zinc neutral stone red orange amber yellow lime green emerald teal cyan sky blue indigo violet purple fuchsia pink rose]
  @flash_kinds ~w[info error warning success] ++ @theme_colors
  @bg_gradient "dark:bg-gradient-to-tr dark:from-slate-900 dark:to-slate-800"
  @root_theme "bg-white text-slate-900  dark:text-white #{@bg_gradient}"
  @shared_link_class "font-black border-b-2 border-dotted text-slate-900 border-slate-900 dark:text-white dark:border-white hover:text-sky-500 hover:border-sky-500 active:text-sky-500 active:border-sky-500 active:border-solid"
  @shared_shadow_class "shadow-md shadow-slate-900/5 dark:shadow-slate-300/5"

  use Phlegethon.Overrides,
    makeup_light: &Makeup.Styles.HTML.StyleMap.default_style/0,
    makeup_dark: &Makeup.Styles.HTML.StyleMap.native_style/0,
    global_style: """
    @layer root {
      /* Firefox */
      * {
        scrollbar-width: thin;
        scrollbar-color: theme(colors.sky.500) transparent;
      }

      /* Chrome, Edge, and Safari */
      *::-webkit-scrollbar {
        @apply w-1;
      }

      *::-webkit-scrollbar-track {
        background: transparent;
      }

      *::-webkit-scrollbar-thumb {
        @apply border-none bg-sky-500 rounded;
      }

      var {
        @apply not-italic rounded font-mono text-sm font-semibold px-2 py-px mx-px;
        @apply bg-slate-900 text-white;
        @apply dark:bg-white dark:text-slate-900;
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
      .progress.slate,
      .progress.slate::-webkit-progress-bar {
        @apply bg-slate-100 dark:bg-slate-900;
      }
      .progress.slate::-webkit-progress-value {
        @apply bg-slate-500;
      }
      .progress.slate::-moz-progress-bar {
        @apply bg-slate-500;
      }
      .progress.gray,
      .progress.gray::-webkit-progress-bar {
        @apply bg-gray-100 dark:bg-gray-900;
      }
      .progress.gray::-webkit-progress-value {
        @apply bg-gray-500;
      }
      .progress.gray::-moz-progress-bar {
        @apply bg-gray-500;
      }
      .progress.zinc,
      .progress.zinc::-webkit-progress-bar {
        @apply bg-zinc-100 dark:bg-zinc-900;
      }
      .progress.zinc::-webkit-progress-value {
        @apply bg-zinc-500;
      }
      .progress.zinc::-moz-progress-bar {
        @apply bg-zinc-500;
      }
      .progress.neutral,
      .progress.neutral::-webkit-progress-bar {
        @apply bg-neutral-100 dark:bg-neutral-900;
      }
      .progress.neutral::-webkit-progress-value {
        @apply bg-neutral-500;
      }
      .progress.neutral::-moz-progress-bar {
        @apply bg-neutral-500;
      }
      .progress.stone,
      .progress.stone::-webkit-progress-bar {
        @apply bg-stone-100 dark:bg-stone-900;
      }
      .progress.stone::-webkit-progress-value {
        @apply bg-stone-500;
      }
      .progress.stone::-moz-progress-bar {
        @apply bg-stone-500;
      }
      .progress.red,
      .progress.red::-webkit-progress-bar {
        @apply bg-red-100 dark:bg-red-900;
      }
      .progress.red::-webkit-progress-value {
        @apply bg-red-500;
      }
      .progress.red::-moz-progress-bar {
        @apply bg-red-500;
      }
      .progress.orange,
      .progress.orange::-webkit-progress-bar {
        @apply bg-orange-100 dark:bg-orange-900;
      }
      .progress.orange::-webkit-progress-value {
        @apply bg-orange-500;
      }
      .progress.orange::-moz-progress-bar {
        @apply bg-orange-500;
      }
      .progress.amber,
      .progress.amber::-webkit-progress-bar {
        @apply bg-amber-100 dark:bg-amber-900;
      }
      .progress.amber::-webkit-progress-value {
        @apply bg-amber-500;
      }
      .progress.amber::-moz-progress-bar {
        @apply bg-amber-500;
      }
      .progress.yellow,
      .progress.yellow::-webkit-progress-bar {
        @apply bg-yellow-100 dark:bg-yellow-900;
      }
      .progress.yellow::-webkit-progress-value {
        @apply bg-yellow-500;
      }
      .progress.yellow::-moz-progress-bar {
        @apply bg-yellow-500;
      }
      .progress.lime,
      .progress.lime::-webkit-progress-bar {
        @apply bg-lime-100 dark:bg-lime-900;
      }
      .progress.lime::-webkit-progress-value {
        @apply bg-lime-500;
      }
      .progress.lime::-moz-progress-bar {
        @apply bg-lime-500;
      }
      .progress.green,
      .progress.green::-webkit-progress-bar {
        @apply bg-green-100 dark:bg-green-900;
      }
      .progress.green::-webkit-progress-value {
        @apply bg-green-500;
      }
      .progress.green::-moz-progress-bar {
        @apply bg-green-500;
      }
      .progress.emerald,
      .progress.emerald::-webkit-progress-bar {
        @apply bg-emerald-100 dark:bg-emerald-900;
      }
      .progress.emerald::-webkit-progress-value {
        @apply bg-emerald-500;
      }
      .progress.emerald::-moz-progress-bar {
        @apply bg-emerald-500;
      }
      .progress.teal,
      .progress.teal::-webkit-progress-bar {
        @apply bg-teal-100 dark:bg-teal-900;
      }
      .progress.teal::-webkit-progress-value {
        @apply bg-teal-500;
      }
      .progress.teal::-moz-progress-bar {
        @apply bg-teal-500;
      }
      .progress.cyan,
      .progress.cyan::-webkit-progress-bar {
        @apply bg-cyan-100 dark:bg-cyan-900;
      }
      .progress.cyan::-webkit-progress-value {
        @apply bg-cyan-500;
      }
      .progress.cyan::-moz-progress-bar {
        @apply bg-cyan-500;
      }
      .progress.sky,
      .progress.sky::-webkit-progress-bar {
        @apply bg-sky-100 dark:bg-sky-900;
      }
      .progress.sky::-webkit-progress-value {
        @apply bg-sky-500;
      }
      .progress.sky::-moz-progress-bar {
        @apply bg-sky-500;
      }
      .progress.blue,
      .progress.blue::-webkit-progress-bar {
        @apply bg-blue-100 dark:bg-blue-900;
      }
      .progress.blue::-webkit-progress-value {
        @apply bg-blue-500;
      }
      .progress.blue::-moz-progress-bar {
        @apply bg-blue-500;
      }
      .progress.indigo,
      .progress.indigo::-webkit-progress-bar {
        @apply bg-indigo-100 dark:bg-indigo-900;
      }
      .progress.indigo::-webkit-progress-value {
        @apply bg-indigo-500;
      }
      .progress.indigo::-moz-progress-bar {
        @apply bg-indigo-500;
      }
      .progress.violet,
      .progress.violet::-webkit-progress-bar {
        @apply bg-violet-100 dark:bg-violet-900;
      }
      .progress.violet::-webkit-progress-value {
        @apply bg-violet-500;
      }
      .progress.violet::-moz-progress-bar {
        @apply bg-violet-500;
      }
      .progress.purple,
      .progress.purple::-webkit-progress-bar {
        @apply bg-purple-100 dark:bg-purple-900;
      }
      .progress.purple::-webkit-progress-value {
        @apply bg-purple-500;
      }
      .progress.purple::-moz-progress-bar {
        @apply bg-purple-500;
      }
      .progress.fuchsia,
      .progress.fuchsia::-webkit-progress-bar {
        @apply bg-fuchsia-100 dark:bg-fuchsia-900;
      }
      .progress.fuchsia::-webkit-progress-value {
        @apply bg-fuchsia-500;
      }
      .progress.fuchsia::-moz-progress-bar {
        @apply bg-fuchsia-500;
      }
      .progress.pink,
      .progress.pink::-webkit-progress-bar {
        @apply bg-pink-100 dark:bg-pink-900;
      }
      .progress.pink::-webkit-progress-value {
        @apply bg-pink-500;
      }
      .progress.pink::-moz-progress-bar {
        @apply bg-pink-500;
      }
      .progress.rose,
      .progress.rose::-webkit-progress-bar {
        @apply bg-rose-100 dark:bg-rose-900;
      }
      .progress.rose::-webkit-progress-value {
        @apply bg-rose-500;
      }
      .progress.rose::-moz-progress-bar {
        @apply bg-rose-500;
      }
    }
    """

  ##############################################################################
  ####    C O R E    C O M P O N E N T S
  ##############################################################################

  override Core, :back do
    set :class, @shared_link_class
    set :icon_class, "w-3 h-3 stroke-current align-baseline"
    set :icon_name, "hero-chevron-left-solid"
  end

  override Core, :button do
    set :class, &__MODULE__.button_class/1
    set :ping_class, &__MODULE__.button_ping_class/1
    set :icon_class, &__MODULE__.button_icon_class/1
    set :colors, @theme_colors
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
    size = passed_assigns[:size]
    variant = passed_assigns[:variant]
    shape = passed_assigns[:shape]
    color = passed_assigns[:color]
    disabled = passed_assigns[:disabled]

    [
      passed_assigns[:case],
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
      "bg-slate-500 text-white": color == "slate" && variant == "solid",
      "border-slate-500 text-slate-500 bg-white hover:bg-slate-500 hover:text-white":
        color == "slate" && variant == "inverted",
      "border-slate-500 text-slate-500": color == "red" && variant == "outline",
      "bg-gray-500 text-white": color == "gray" && variant == "solid",
      "border-gray-500 text-gray-500 bg-white hover:bg-gray-500 hover:text-white":
        color == "gray" && variant == "inverted",
      "border-gray-500 text-gray-500": color == "red" && variant == "outline",
      "bg-zinc-500 text-white": color == "zinc" && variant == "solid",
      "border-zinc-500 text-zinc-500 bg-white hover:bg-zinc-500 hover:text-white":
        color == "zinc" && variant == "inverted",
      "border-zinc-500 text-zinc-500": color == "red" && variant == "outline",
      "bg-neutral-500 text-white": color == "neutral" && variant == "solid",
      "border-neutral-500 text-neutral-500 bg-white hover:bg-neutral-500 hover:text-white":
        color == "neutral" && variant == "inverted",
      "border-neutral-500 text-neutral-500": color == "red" && variant == "outline",
      "bg-neutral-500 text-white": color == "neutral" && variant == "solid",
      "border-neutral-500 text-neutral-500 bg-white hover:bg-neutral-500 hover:text-white":
        color == "neutral" && variant == "inverted",
      "border-neutral-500 text-neutral-500": color == "red" && variant == "outline",
      "bg-stone-500 text-white": color == "stone" && variant == "solid",
      "border-stone-500 text-stone-500 bg-white hover:bg-stone-500 hover:text-white":
        color == "stone" && variant == "inverted",
      "border-stone-500 text-stone-500": color == "red" && variant == "outline",
      "bg-red-500 text-white": color == "red" && variant == "solid",
      "border-red-500 text-red-500 bg-white hover:bg-red-500 hover:text-white":
        color == "red" && variant == "inverted",
      "border-red-500 text-red-500": color == "red" && variant == "outline",
      "bg-orange-500 text-black": color == "orange" && variant == "solid",
      "border-orange-500 text-orange-500 bg-black hover:bg-orange-500 hover:text-black":
        color == "orange" && variant == "inverted",
      "border-orange-500 text-orange-500": color == "orange" && variant == "outline",
      "bg-amber-500 text-black": color == "amber" && variant == "solid",
      "border-amber-500 text-amber-500 bg-black hover:bg-amber-500 hover:text-black":
        color == "amber" && variant == "inverted",
      "border-amber-500 text-amber-500": color == "amber" && variant == "outline",
      "bg-yellow-500 text-black": color == "yellow" && variant == "solid",
      "border-yellow-500 text-yellow-500 bg-black hover:bg-yellow-500 hover:text-black":
        color == "yellow" && variant == "inverted",
      "border-yellow-500 text-yellow-500": color == "yellow" && variant == "outline",
      "bg-lime-500 text-black": color == "lime" && variant == "solid",
      "border-lime-500 text-lime-500 bg-black hover:bg-lime-500 hover:text-black":
        color == "lime" && variant == "inverted",
      "border-lime-500 text-lime-500": color == "lime" && variant == "outline",
      "bg-green-500 text-black": color == "green" && variant == "solid",
      "border-green-500 text-green-500 bg-black hover:bg-green-500 hover:text-black":
        color == "green" && variant == "inverted",
      "border-green-500 text-green-500": color == "green" && variant == "outline",
      "bg-emerald-500 text-black": color == "emerald" && variant == "solid",
      "border-emerald-500 text-emerald-500 bg-black hover:bg-emerald-500 hover:text-black":
        color == "emerald" && variant == "inverted",
      "border-emerald-500 text-emerald-500": color == "emerald" && variant == "outline",
      "bg-teal-500 text-black": color == "teal" && variant == "solid",
      "border-teal-500 text-teal-500 bg-black hover:bg-teal-500 hover:text-black":
        color == "teal" && variant == "inverted",
      "border-teal-500 text-teal-500": color == "teal" && variant == "outline",
      "bg-cyan-500 text-black": color == "cyan" && variant == "solid",
      "border-cyan-500 text-cyan-500 bg-black hover:bg-cyan-500 hover:text-black":
        color == "cyan" && variant == "inverted",
      "border-cyan-500 text-cyan-500": color == "cyan" && variant == "outline",
      "bg-sky-500 text-white": color == "sky" && variant == "solid",
      "border-sky-500 text-sky-500 bg-white hover:bg-sky-500 hover:text-white":
        color == "sky" && variant == "inverted",
      "border-sky-500 text-sky-500": color == "sky" && variant == "outline",
      "bg-blue-500 text-white": color == "blue" && variant == "solid",
      "border-blue-500 text-blue-500 bg-white hover:bg-blue-500 hover:text-white":
        color == "blue" && variant == "inverted",
      "border-blue-500 text-blue-500": color == "blue" && variant == "outline",
      "bg-indigo-500 text-white": color == "indigo" && variant == "solid",
      "border-indigo-500 text-indigo-500 bg-white hover:bg-indigo-500 hover:text-white":
        color == "indigo" && variant == "inverted",
      "border-indigo-500 text-indigo-500": color == "indigo" && variant == "outline",
      "bg-violet-500 text-white": color == "violet" && variant == "solid",
      "border-violet-500 text-violet-500 bg-white hover:bg-violet-500 hover:text-white":
        color == "violet" && variant == "inverted",
      "border-violet-500 text-violet-500": color == "violet" && variant == "outline",
      "bg-purple-500 text-white": color == "purple" && variant == "solid",
      "border-purple-500 text-purple-500 bg-white hover:bg-purple-500 hover:text-white":
        color == "purple" && variant == "inverted",
      "border-purple-500 text-purple-500": color == "purple" && variant == "outline",
      "bg-fuchsia-500 text-white": color == "fuchsia" && variant == "solid",
      "border-fuchsia-500 text-fuchsia-500 bg-white hover:bg-fuchsia-500 hover:text-white":
        color == "fuchsia" && variant == "inverted",
      "border-fuchsia-500 text-fuchsia-500": color == "fuchsia" && variant == "outline",
      "bg-pink-500 text-white": color == "pink" && variant == "solid",
      "border-pink-500 text-pink-500 bg-white hover:bg-pink-500 hover:text-white":
        color == "pink" && variant == "inverted",
      "border-pink-500 text-pink-500": color == "pink" && variant == "outline",
      "bg-rose-500 text-white": color == "rose" && variant == "solid",
      "border-rose-500 text-rose-500 bg-white hover:bg-rose-500 hover:text-white":
        color == "rose" && variant == "inverted",
      "border-rose-500 text-rose-500": color == "rose" && variant == "outline"
    ]
  end

  def button_ping_class(passed_assigns) do
    shape = passed_assigns[:shape]

    [
      "block",
      "absolute",
      "rounded-full",
      "w-3",
      "h-3",
      "bg-red-500",
      "-top-1.5 -right-1.5": shape != "pill",
      "-top-1 -right-1": shape == "pill"
    ]
  end

  def button_icon_class(passed_assigns) do
    size = passed_assigns[:size]

    [
      "h-5 w-5": size in ["md", "lg"],
      "h-6 w-6": size == "xl"
    ]
  end

  override Core, :error do
    set :class,
        "phx-no-feedback:hidden flex gap-1 text-sm leading-6 text-red-600 dark:text-red-500"

    set :icon_name, "hero-exclamation-circle-mini"
    set :icon_class, "h-5 w-5 flex-none inline"
  end

  override Core, :flash do
    set :class, &__MODULE__.flash_class/1
    set :control_class, "grid grid-cols-[1fr,auto] items-center gap-1"
    set :close_icon_class, "h-5 w-5 stroke-current opacity-40 group-hover:opacity-70 block -mr-2"
    set :close_icon_name, "hero-x-mark-mini"
    set :icon_name, &__MODULE__.flash_icon_name/1
    set :kind, "slate"
    set :kinds, @flash_kinds
    set :message_class, "text-sm whitespace-pre-wrap"
    set :progress_class, "border border-black/25"
    set :title, &__MODULE__.flash_title/1
    set :title_class, "flex items-center gap-1.5 text-sm font-semibold leading-6"
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

    [
      "hidden w-80 sm:w-96 rounded p-3 group relative z-50 ring-1",
      @shared_shadow_class,
      "pt-1": close || ttl > 0,
      "cursor-pointer": close,
      "bg-slate-100 text-slate-900 ring-slate-500 fill-slate-900 dark:bg-slate-900 dark:text-slate-100 dark:ring-slate-500 dark:fill-slate-100":
        kind == "slate" || style_for_kind == "slate" ||
          (style_for_kind not in @theme_colors and kind not in @theme_colors),
      "bg-gray-100 text-gray-900 ring-gray-500 fill-gray-900 dark:bg-gray-900 dark:text-gray-100 dark:ring-gray-500 dark:fill-gray-100":
        kind == "gray" || style_for_kind == "gray",
      "bg-zinc-100 text-zinc-900 ring-zinc-500 fill-zinc-900 dark:bg-zinc-900 dark:text-zinc-100 dark:ring-zinc-500 dark:fill-zinc-100":
        kind == "zinc" || style_for_kind == "zinc",
      "bg-neutral-100 text-neutral-900 ring-neutral-500 fill-neutral-900 dark:bg-neutral-900 dark:text-neutral-100 dark:ring-neutral-500 dark:fill-neutral-100":
        kind == "neutral" || style_for_kind == "neutral",
      "bg-stone-100 text-stone-900 ring-stone-500 fill-stone-900 dark:bg-stone-900 dark:text-stone-100 dark:ring-stone-500 dark:fill-stone-100":
        kind == "stone" || style_for_kind == "stone",
      "bg-red-100 text-red-900 ring-red-500 fill-red-900 dark:bg-red-900 dark:text-red-100 dark:ring-red-500 dark:fill-red-100":
        kind == "red" || style_for_kind == "red" || kind == "error" || style_for_kind == "error",
      "bg-orange-100 text-orange-900 ring-orange-500 fill-orange-900 dark:bg-orange-900 dark:text-orange-100 dark:ring-orange-500 dark:fill-orange-100":
        kind == "orange" || style_for_kind == "orange",
      "bg-amber-100 text-amber-900 ring-amber-500 fill-amber-900 dark:bg-amber-900 dark:text-amber-100 dark:ring-amber-500 dark:fill-amber-100":
        kind == "amber" || style_for_kind == "amber",
      "bg-yellow-100 text-yellow-900 ring-yellow-500 fill-yellow-900 dark:bg-yellow-900 dark:text-yellow-100 dark:ring-yellow-500 dark:fill-yellow-100":
        kind == "yellow" || style_for_kind == "yellow" || kind == "warning" ||
          style_for_kind == "warning",
      "bg-lime-100 text-lime-900 ring-lime-500 fill-lime-900 dark:bg-lime-900 dark:text-lime-100 dark:ring-lime-500 dark:fill-lime-100":
        kind == "lime" || style_for_kind == "lime",
      "bg-green-100 text-green-900 ring-green-500 fill-green-900 dark:bg-green-900 dark:text-green-100 dark:ring-green-500 dark:fill-green-100":
        kind == "green" || style_for_kind == "green" || kind == "success" ||
          style_for_kind == "success",
      "bg-emerald-100 text-emerald-900 ring-emerald-500 fill-emerald-900 dark:bg-emerald-900 dark:text-emerald-100 dark:ring-emerald-500 dark:fill-emerald-100":
        kind == "emerald" || style_for_kind == "emerald",
      "bg-teal-100 text-teal-900 ring-teal-500 fill-teal-900 dark:bg-teal-900 dark:text-teal-100 dark:ring-teal-500 dark:fill-teal-100":
        kind == "teal" || style_for_kind == "teal",
      "bg-cyan-100 text-cyan-900 ring-cyan-500 fill-cyan-900 dark:bg-cyan-900 dark:text-cyan-100 dark:ring-cyan-500 dark:fill-cyan-100":
        kind == "cyan" || style_for_kind == "cyan",
      "bg-sky-100 text-sky-900 ring-sky-500 fill-sky-900 dark:bg-sky-900 dark:text-sky-100 dark:ring-sky-500 dark:fill-sky-100":
        kind == "sky" || style_for_kind == "sky" || kind == "info" || style_for_kind == "info",
      "bg-blue-100 text-blue-900 ring-blue-500 fill-blue-900 dark:bg-blue-900 dark:text-blue-100 dark:ring-blue-500 dark:fill-blue-100":
        kind == "blue" || style_for_kind == "blue",
      "bg-indigo-100 text-indigo-900 ring-indigo-500 fill-indigo-900 dark:bg-indigo-900 dark:text-indigo-100 dark:ring-indigo-500 dark:fill-indigo-100":
        kind == "indigo" || style_for_kind == "indigo",
      "bg-violet-100 text-violet-900 ring-violet-500 fill-violet-900 dark:bg-violet-900 dark:text-violet-100 dark:ring-violet-500 dark:fill-violet-100":
        kind == "violet" || style_for_kind == "violet",
      "bg-purple-100 text-purple-900 ring-purple-500 fill-purple-900 dark:bg-purple-900 dark:text-purple-100 dark:ring-purple-500 dark:fill-purple-100":
        kind == "purple" || style_for_kind == "purple",
      "bg-fuchsia-100 text-fuchsia-900 ring-fuchsia-500 fill-fuchsia-900 dark:bg-fuchsia-900 dark:text-fuchsia-100 dark:ring-fuchsia-500 dark:fill-fuchsia-100":
        kind == "fuchsia" || style_for_kind == "fuchsia",
      "bg-pink-100 text-pink-900 ring-pink-500 fill-pink-900 dark:bg-pink-900 dark:text-pink-100 dark:ring-pink-500 dark:fill-pink-100":
        kind == "pink" || style_for_kind == "pink",
      "bg-rose-100 text-rose-900 ring-rose-500 fill-rose-900 dark:bg-rose-900 dark:text-rose-100 dark:ring-rose-500 dark:fill-rose-100":
        kind == "rose" || style_for_kind == "rose"
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
    set :class, "absolute top-2 right-2 grid gap-2"
    set :include_kinds, @flash_kinds
  end

  override Core, :header do
    set :class, &__MODULE__.header_class/1
    set :title_class, &__MODULE__.header_title_class/1
    set :subtitle_class, "mt-2 text-sm leading-6 text-slate-600 dark:text-slate-200"
    set :actions_class, "no-flex flex gap-2"
  end

  def header_class(passed_assigns) do
    actions = passed_assigns[:actions]

    ["flex items-center justify-between gap-6": actions != []]
  end

  def header_title_class(passed_assigns) do
    actions = passed_assigns[:actions]

    [
      "text-lg font-semibold leading-8 text-slate-800 dark:text-slate-50",
      "text-center": actions == []
    ]
  end

  override Core, :icon do
    set :class, "h-4 w-4 inline-block align-text-bottom"
  end

  @input_description_class "text-xs text-slate-600 dark:text-slate-400"
  override Core, :input do
    set :class, "grid gap-1 content-start"
    set :input_class, &__MODULE__.input_class/1

    set :input_check_label_class,
        "flex items-center gap-2 text-sm leading-6 text-slate-800 dark:text-slate-100 font-semibold"

    set :description_class, @input_description_class
    set :clear_on_escape, true
  end

  def input_class(passed_assigns) do
    type = passed_assigns[:type]

    errors? =
      case passed_assigns[:errors] do
        [] -> false
        [_ | _] -> true
      end

    [
      "rounded-lg",
      "block w-full border-slate-300 py-[7px] px-[11px]",
      "sm:text-sm sm:leading-6",
      "bg-transparent text-slate-900 dark:text-white",
      "focus:outline-none focus:ring-4",
      "phx-no-feedback:border-slate-300 phx-no-feedback:focus:border-slate-400 phx-no-feedback:focus:ring-slate-800/5",
      "border-slate-300 dark:border-slate-700 focus:border-slate-500 focus:ring-slate-800/5 dark:focus:border-slate-50 dark:focus:ring-slate-50/25":
        !errors?,
      "border-red-600 focus:border-red-600 focus:ring-red-600/10 dark:border-red-500 dark:focus:border-red-500 dark:focus:ring-red-500/25":
        errors?,
      "w-auto rounded text-sky-500 focus:ring-sky-500 dark:text-sky-500 dark:focus:ring-sky-500":
        type == "checkbox",
      "py-2 px-3": type == "select",
      "min-h-[6rem]": type == "textarea"
    ]
  end

  override Core, :label do
    set :class, "block text-sm font-semibold leading-6 text-slate-800 dark:text-slate-100"
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
        "relative divide-y divide-slate-100 border-t border-slate-200 text-sm leading-6 "

    set :tr_class, "relative group hover:bg-slate-50"
    set :td_class, &__MODULE__.table_td_class/1
    set :action_td_class, "p-0 w-14"
    set :action_wrapper_class, "relative whitespace-nowrap py-4 text-right text-sm font-medium"
    set :action_class, "relative ml-4 font-semibold leading-6 hover:text-slate-700"
  end

  def table_td_class(passed_assigns) do
    row_click = passed_assigns[:row_click]
    ["p-0", "hover:cursor-pointer": row_click]
  end

  ##############################################################################
  ####    P H L E G E T H O N    C O M P O N E N T S
  ##############################################################################

  override Extra, :a do
    set :class, @shared_link_class
    set :replace, false
  end

  override Extra, :code do
    set :class,
        ["makeup whitespace-pre-wrap p-4 rounded relative", @shared_shadow_class]

    set :copy, true
    set :copy_label, "Copy"
    set :copy_class, "absolute top-1 right-1"
  end

  override Extra, :copy_to_clipboard do
    set :class, &__MODULE__.button_class/1
    set :icon_class, &__MODULE__.button_icon_class/1
    set :colors, @theme_colors
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

  override Extra, :nav_link do
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
    is_current = passed_assigns[:is_current]

    [
      @shared_link_class,
      "border-solid cursor-default text-slate-900 dark:text-white border-slate-900 dark:border-white":
        is_current
    ]
  end

  override Extra, :progress do
    set :class, &__MODULE__.progress_class/1
    set :size, "md"
    set :sizes, ~w[xs sm md lg xl]
    set :color, "sky"
    set :colors, @theme_colors
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

    size = passed_assigns[:size]

    [
      "progress",
      color,
      "h-1": size == "xs",
      "h-2": size == "sm",
      "h-4": size == "md",
      "h-6": size == "lg",
      "h-8": size == "xl"
    ]
  end

  override Extra, :spinner do
    set :class, &__MODULE__.spinner_class/1
    set :size, "md"
    set :sizes, ~w[xs sm md lg xl]
  end

  def spinner_class(passed_assigns) do
    size = passed_assigns[:size]
    show = passed_assigns[:show]

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
        "group hover:relative inline-block select-none hover:bg-sky-500 rounded cursor-help"

    set :tooltip_class,
        [
          "absolute invisible select-none group-hover:visible normal-case block z-10",
          @shared_shadow_class
        ]

    set :tooltip_text_class,
        "bg-sky-500 text-white min-w-[20rem] p-2 rounded text-sm font-normal whitespace-pre"

    set :icon_name, "hero-question-mark-circle-solid"
    set :vertical_offset, "2.25rem"
    set :horizontal_offset, "0"
  end

  ##############################################################################
  ####    S M A R T    C O M P O N E N T S
  ##############################################################################

  override Autocomplete, :render do
    set :class, "grid gap-1 content-start"
    set :input_class, &__MODULE__.input_class/1
    set :description_class, @input_description_class
    set :throttle_time, 212
    set :option_label_key, :label
    set :option_value_key, :id
    set :prompt, "Search options"

    set :listbox_class, [
      "absolute z-10 grid content-start top-0 left-0",
      "sm:text-sm sm:leading-6",
      "bg-white text-slate-900 dark:bg-gradient-to-tr dark:from-slate-900 dark:to-slate-800 dark:text-white",
      "border border-slate-300 rounded-lg",
      # "ring-4 ring-slate-800/5 dark:ring-slate-50/25",
      "shadow-lg "
    ]

    set :listbox_option_class, &__MODULE__.autocomplete_listbox_option_class/1
  end

  def autocomplete_listbox_option_class(passed_assigns) do
    results = passed_assigns[:results]

    [
      "aria-selected:bg-sky-500 aria-selected:text-white",
      "py-1 px-2 rounded-lg",
      "cursor-pointer hover:bg-slate-300 hover:text-slate-900": results != [],
      "cursor-default": results == []
    ]
  end

  override SmartForm, :smart_form do
    set :actions_class, "mt-2 flex items-center justify-between gap-6"
    set :class, &__MODULE__.smart_form_class/1
    set :autocomplete, "off"
  end

  def smart_form_class(passed_assigns) do
    [
      "grid gap-2",
      get_by_path(passed_assigns, [:phlegethon_form, :class])
    ]
  end

  override SmartForm, :render_field do
    set :field_group_class, &__MODULE__.smart_form_field_group_class/1
    set :field_group_label_class, "font-black col-span-full"
  end

  def smart_form_field_group_class(passed_assigns) do
    [
      "grid col-span-full gap-2 p-2 border border-solid rounded-lg",
      "border-slate-300 dark:border-slate-700",
      get_by_path(passed_assigns, [:field, :class])
    ]
  end

  # override SmartDataTable, :render do
  #   set :class, "grid"
  #   set :phlegethon_table, &__MODULE__.smart_data_table_phlegethon_table/1
  # end

  # def smart_data_table_phlegethon_table(passed_assigns) do
  #   UI.table_for(passed_assigns[:resource])
  # end
end
