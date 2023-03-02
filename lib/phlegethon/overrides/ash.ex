# defmodule Phlegethon.Overrides.Ash do
#   @moduledoc """
#   This is the theme for [AshHQ](https://ash-hq.org/). It builds on `Phlegethon.Overrides.Default` and `Phlegethon.Overrides.Essential`, overriding only the settings needed to apply its theme.

#   In addition to proving Ash projects with a consistent preset, it is an example of how to tweak a handful of settings while leaving most of the configuration to the default preset.
#   """

#   ##############################################################################
#   ####    S T Y L E    S E T T I N G S
#   ##############################################################################

#   use Phlegethon.Overrides,
#     makeup_light: &Makeup.Styles.HTML.StyleMap.autumn_style/0,
#     makeup_dark: &Makeup.Styles.HTML.StyleMap.monokai_style/0,
#     extend_colors: %{
#       "root" => "#ffffff",
#       "root-dark" => "#0c0c0f",
#       "root-fg" => "#0c0c0f",
#       "root-fg-dark" => "#ffffff",
#       "root-2" => "#e5e7eb",
#       "root-2-dark" => "#2e303d",
#       "root-3" => "#f3f4f6",
#       "root-3-dark" => "#46495d",
#       "brand-1" => "#ff914d",
#       "brand-2" => "#ffbd59",
#       "brand-3" => "#ff5757"
#     },
#     global_style: """
#     @layer root {
#       /* Firefox */
#       * {
#         scrollbar-width: thin;
#         scrollbar-color: theme(colors.brand-1) transparent;
#       }

#       /* Chrome, Edge, and Safari */
#       *::-webkit-scrollbar {
#         @apply w-1;
#       }

#       *::-webkit-scrollbar-track {
#         background: transparent;
#       }

#       *::-webkit-scrollbar-thumb {
#         @apply border-none bg-brand-1 rounded;
#       }

#       var {
#         @apply not-italic rounded font-mono text-sm font-semibold px-2 py-px mx-px;
#         @apply bg-root-fg text-root;
#         @apply dark:bg-root-fg-dark dark:text-root-dark;
#       }
#     }

#     @layer component {
#       .progress {
#         @apply appearance-none rounded;
#       }
#       .progress::-webkit-progress-value {
#         @apply rounded;
#       }
#       .progress.error::-webkit-progress-bar {
#         @apply bg-red-600;
#       }
#       .progress.error::-webkit-progress-value {
#         @apply bg-red-400;
#       }
#       .progress.warning::-webkit-progress-bar {
#         @apply bg-yellow-600;
#       }
#       .progress.warning::-webkit-progress-value {
#         @apply bg-yellow-400;
#       }
#       .progress.success::-webkit-progress-bar {
#         @apply bg-green-600;
#       }
#       .progress.success::-webkit-progress-value {
#         @apply bg-green-400;
#       }
#       .progress.info::-webkit-progress-bar {
#         @apply bg-root;
#       }
#       .progress.info::-webkit-progress-value {
#         @apply bg-root-fg;
#       }
#       .dark .progress.info::-webkit-progress-bar {
#         @apply bg-root-dark;
#       }
#       .dark .progress.info::-webkit-progress-value {
#         @apply bg-root-fg-dark;
#       }
#       .progress::-moz-progress-bar {
#         /* TODO: style rules for FF */
#       }
#     }
#     """

#   ##############################################################################
#   ####    C O R E    C O M P O N E N T S
#   ##############################################################################

#   override Core, :back do
#     set :class, "text-sm font-semibold hover:text-brand-3"
#     set :icon_class, "w-3 h-3 stroke-current align-baseline"
#   end

#   override Core, :button do
#     set :class, &__MODULE__.button_class/1
#     set :colors, ~w[root primary red yellow green]
#     set :color, "primary"
#   end

#   def button_class(assigns) do
#     size = assigns[:size]
#     pill = assigns[:pill]
#     color = assigns[:color]
#     outline = assigns[:outline]
#     shadow = assigns[:shadow]
#     shadow_hover = assigns[:shadow_hover]
#     shadow_focus = assigns[:shadow_focus]

#     [
#       "font-black",
#       "uppercase",
#       "text-center",
#       "inline-block",
#       "cursor-pointer",
#       "disabled:cursor-not-allowed",
#       "disabled:opacity-50",
#       "appearance-none",
#       "select-none",
#       "px-2",
#       "whitespace-nowrap",
#       "hover:scale-105",
#       "active:opacity-50",
#       "text-xs": size == "xs",
#       "text-sm": size == "sm",
#       "text-base": size == "md",
#       "text-lg": size == "lg",
#       "text-xl": size == "xl",
#       "rounded-full": pill,
#       "rounded-sm": !pill && size == "xs",
#       rounded: !pill && size == "md",
#       rounded: !pill && size == "lg",
#       rounded: !pill && size == "xl",
#       "rounded-sm": !pill && size == "sm",
#       "border border-solid": outline,
#       "border-2": outline && size == "md",
#       "border-2": outline && size == "lg",
#       "border-2": outline && size == "xl",
#       "shadow-lg": shadow,
#       "hover:shadow-lg": shadow_hover,
#       "focus:shadow-lg": shadow_focus,
#       "shadow-root dark:shadow-root-fg-dark":
#         (shadow || shadow_hover || shadow_focus) && color == "root",
#       "shadow-brand-1 dark:shadow-brand-3":
#         (shadow || shadow_hover || shadow_focus) && color == "primary",
#       "shadow-red-400": (shadow || shadow_hover || shadow_focus) && color == "red",
#       "shadow-yellow-400": (shadow || shadow_hover || shadow_focus) && color == "yellow",
#       "shadow-green-400": (shadow || shadow_hover || shadow_focus) && color == "green",
#       "bg-brand-1 dark:bg-brand-3": color == "primary" && !outline,
#       "text-brand-1 dark:text-brand-3 border-brand-1 dark:border-brand-3":
#         color == "primary" && outline,
#       "bg-root-fg dark:bg-root-fg-dark text-root dark:text-root-dark":
#         color == "root" && !outline,
#       "text-root-fg dark:text-root-fg-dark border-root-fg dark:border-root-fg-dark":
#         color == "root" && outline,
#       "bg-red-500 text-white": color == "red" && !outline,
#       "text-red-500 border-red-500": color == "red" && outline,
#       "bg-green-500 text-white": color == "green" && !outline,
#       "text-green-500 border-green-500": color == "green" && outline,
#       "bg-yellow-400 text-black": color == "yellow" && !outline,
#       "text-yellow-400 border-yellow-400": color == "yellow" && outline
#     ]
#   end

#   override Core, :error do
#     set :class, "phx-no-feedback:hidden flex gap-3 text-sm text-red-500"
#     set :icon_name, "hero-exclamation-circle-mini"
#     set :icon_class, "mt-0.5 h-5 w-5 flex-none fill-red-500"
#   end

#   @flash_kinds ~w[info error warning success]

#   override Core, :flash do
#     set :class, &__MODULE__.flash_class/1
#     set :close_button_class, "absolute top-2 right-1 p-2"
#     set :close_icon_class, "h-5 w-5 stroke-current opacity-40 group-hover:opacity-70"
#     set :close_icon_name, "hero-x-mark-mini"
#     set :icon_name, &__MODULE__.flash_icon_name/1
#     set :kind, "info"
#     set :kinds, @flash_kinds
#     set :message_class, "text-sm whitespace-pre-wrap"
#     set :progress_class, "absolute top-1 left-0 w-full h-1"
#     set :title, &__MODULE__.flash_title/1
#     set :title_class, "flex items-center gap-1.5 text-sm font-semibold leading-6"
#   end

#   def flash_title(assigns) do
#     case assigns[:kind] do
#       "info" -> "Information"
#       "error" -> "Error"
#       "warning" -> "Warning"
#       "success" -> "Success"
#       _ -> nil
#     end
#   end

#   def flash_icon_name(assigns) do
#     case assigns[:kind] do
#       "info" -> "hero-information-circle-mini"
#       "error" -> "hero-exclamation-circle-mini"
#       "warning" -> "hero-exclamation-triangle-mini"
#       "success" -> "hero-check-circle-mini"
#       _ -> "hero-information-circle-mini"
#     end
#   end

#   def flash_class(assigns) do
#     kind = assigns[:kind]
#     style_for_kind = assigns[:style_for_kind]
#     close = assigns[:close]

#     [
#       "hidden w-80 sm:w-96 rounded p-3 shadow-md shadow-zinc-900/5 group relative z-10",
#       [
#         "cursor-pointer": close,
#         "bg-red-500 text-white": kind == "error" || style_for_kind == "error",
#         "bg-yellow-500 text-black": kind == "warning" || style_for_kind == "warning",
#         "bg-green-500 text-black": kind == "success" || style_for_kind == "success",
#         "bg-root text-root-fg dark:bg-root-dark dark:text-root-fg-dark ring-1 ring-root-fg dark:ring-root-fg-dark":
#           kind == "info" || style_for_kind == "info" ||
#             (style_for_kind not in @flash_kinds and kind not in @flash_kinds)
#       ]
#     ]
#   end

#   override Core, :flash_group do
#     set :class, "absolute top-2 right-2 grid gap-2"
#     set :include_kinds, @flash_kinds
#   end

#   override Core, :header do
#     set :class, &__MODULE__.header_class/1
#     set :title_class, &__MODULE__.header_title_class/1
#     set :subtitle_class, "mt-2 text-lg font-semibold text uppercase text-brand-3"
#     set :actions_class, "no-flex"
#   end

#   def header_class(assigns) do
#     actions = assigns[:actions]

#     ["flex items-center justify-between gap-6": actions != []]
#   end

#   def header_title_class(assigns) do
#     actions = assigns[:actions]

#     ["leading-normal font-bold text-5xl text-brand-2", ["text-center": actions == []]]
#   end

#   override Core, :input do
#     set :class, "grid gap-1 content-start"
#     set :input_class, &__MODULE__.input_class/1
#     set :description_class, "text-xs"
#   end

#   def input_class(assigns) do
#     type = assigns[:type]

#     errors? =
#       case assigns[:errors] do
#         [] -> false
#         [_ | _] -> true
#       end

#     [
#       "block",
#       "w-full",
#       "rounded",
#       "border",
#       "border-solid",
#       "focus:ring-4",
#       "bg-root dark:bg-root-dark",
#       "text-root-fg dark:text-root-fg-dark",
#       [
#         "border-root-fg dark:border-root-fg-dark": !errors?,
#         "border-red-500 focus:border-red-500 focus:ring-red-500": errors?,
#         "focus:ring-brand-1": !errors?,
#         # "": type == "text",
#         "min-h-[6rem]": type == "textarea"
#       ]
#     ]
#   end

#   override Core, :label do
#     set :class, "block text-sm font-black text-root-fg dark:text-root-fg-dark"
#   end

#   override Core, :simple_form do
#     set :class, "grid gap-2"
#     set :actions_class, "mt-2 flex items-center justify-between gap-6"
#   end

#   override Core, :list do
#     set :class, "-my-4 divide-y divide-zinc-100"
#     set :wrapper_class, "flex gap-4 py-4 sm:gap-8"
#     set :dt_class, "w-1/4 flex-none text-[0.8125rem] leading-6 text-zinc-500"
#     set :dd_class, "text-sm leading-6 text-zinc-700"
#   end

#   override Core, :modal do
#     set :class, "relative z-50 hidden"
#   end

#   override Core, :table do
#     set :class, "w-full"
#     set :thead_class, "text-left text-[0.8125rem] leading-6"
#     set :th_label_class, "p-0 pb-4 pr-6 font-normal"
#     set :th_action_class, "relative p-0 pb-4"

#     set :tbody_class,
#         "relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 "

#     set :tr_class, "relative group hover:bg-zinc-50"
#     set :td_class, &__MODULE__.table_td_class/1
#     set :action_td_class, "p-0 w-14"
#     set :action_wrapper_class, "relative whitespace-nowrap py-4 text-right text-sm font-medium"
#     set :action_class, "relative ml-4 font-semibold leading-6 hover:text-zinc-700"
#   end

#   def table_td_class(assigns) do
#     row_click = assigns[:row_click]
#     ["p-0", ["hover:cursor-pointer": row_click]]
#   end

#   ##############################################################################
#   ####    P H L E G E T H O N    C O M P O N E N T S
#   ##############################################################################

#   override Icon, :icon do
#     set :class, "h-4 w-4 inline-block align-text-bottom"
#     set :kind, :solid
#   end

#   override Extra, :code do
#     set :class,
#         "makeup whitespace-pre-wrap p-4 rounded bg-root-2 dark:bg-root-2-dark shadow"
#   end

#   @progress_colors ~w[info error warning success]
#   override Extra, :progress do
#     set :class, &__MODULE__.progress_class/1
#     set :size, "md"
#     set :sizes, ~w[xs sm md lg xl]
#     set :color, "info"
#     set :colors, @progress_colors
#   end

#   def progress_class(assigns) do
#     color = assigns[:color]
#     size = assigns[:size]

#     [
#       "progress",
#       [
#         "h-1": size == "xs",
#         "h-2": size == "sm",
#         "h-4": size == "md",
#         "h-6": size == "lg",
#         "h-8": size == "xl",
#         error: color == "error",
#         warning: color == "warning",
#         success: color == "success",
#         info: color == "info" || color not in @progress_colors
#       ]
#     ]
#   end
# end
