defmodule Phlegethon.Overrides.Essential do
  @moduledoc """
  This is the essential configuration for Phlegethon components.

  It handles things that components depend on, primarily functions that assign metadata via the override system. This does not cover any style.
  """

  use Phlegethon.Overrides

  ##############################################################################
  ####    C O R E    C O M P O N E N T S
  ##############################################################################

  override Core, :back do
    set :icon_kind, :solid
    set :icon_name, :chevron_left
  end

  override Core, :button do
    set :variant, "solid"
    set :variants, ~w[solid inverted outline]
    set :shape, "rounded"
    set :shapes, ~w[square rounded pill]
    set :size, "md"
    set :sizes, ~w[xs sm md lg xl]
    set :icon_kind, :solid
  end

  override Core, :flash do
    set :autoshow, true
    set :close, true
    set :ttl, 10_000
    set :style_for_kind, &__MODULE__.flash_style_for_kind/1
    set :show_js, &__MODULE__.flash_show_js/2
    set :hide_js, &__MODULE__.flash_hide_js/2
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

  override Core, :input do
    set :clear_on_escape, true
  end

  override Core, :modal do
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

  ##############################################################################
  ####    P H L E G E T H O N    C O M P O N E N T S
  ##############################################################################

  override Extra, :spinner do
    set :size, "md"
    set :sizes, ~w[xs sm md lg xl]
  end

  override Extra, :tooltip do
    set :class,
        "group hover:relative inline-block select-none hover:bg-brand-1 rounded-sm cursor-help"

    set :tooltip_class,
        "bg-root-2 text-root-fg dark:bg-root-2-dark dark:text-root-fg-dark min-w-[20rem] block shadow p-2 rounded text-sm font-normal whitespace-pre"

    set :tooltip_text_class, "absolute invisible select-none group-hover:visible normal-case"
    set :icon_kind, :solid
    set :icon_name, :question_mark_circle
    set :vertical_offset, "2em"
    set :horizontal_offset, "0"
  end

  ##############################################################################
  ####    S M A R T    C O M P O N E N T S
  ##############################################################################

  override SmartForm, :smart_form do
    set :action_info, &__MODULE__.smart_form_action_info/1
    set :autocomplete, "off"
    set :phlegethon_form, &__MODULE__.smart_form_phlegethon_form/1
  end

  def smart_form_phlegethon_form(assigns) do
    UI.form_for(assigns[:resource], assigns[:action])
  end

  def smart_form_action_info(assigns) do
    UI.action(assigns[:resource], assigns[:action])
  end

  override SmartForm, :render_field do
    set :attribute, &__MODULE__.smart_form_field_attribute/1
  end

  def smart_form_field_attribute(%{
        resource: resource,
        field: %Phlegethon.Resource.Form.Field{name: name}
      }) do
    UI.attribute(resource, name)
  end

  def smart_form_field_attribute(_assigns), do: nil
end
