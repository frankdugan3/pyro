defmodule Phlegethon.Components.Icon do
  @moduledoc """
  An icon component and some tooling for authoring components that render icons.
  """
  use Phlegethon.Component

  @icon_kind_options ~w[outline solid mini]a
  @icon_name_options Heroicons.__info__(:functions)
                     |> Enum.reduce([], fn
                       {:__phoenix_component_verify__, _}, acc -> acc
                       {key, 1}, acc -> [key | acc]
                       _, acc -> acc
                     end)

  @doc """
  Provides conveniences for authoring components that use icons.

  - Imports the `icon/1` component
  - Defines `@icon_kind_options` (the list of possible icon kinds)
  - Defines `@icon_name_options` (the list of possible icon names)

  The options are useful for compile-time validation of attributes that get passed to the icon component, e.g:

  ## Examples

  ```elixir
  defmodule MyAppWeb.Components do
    use Phlegethon.Components.Icon

    attr :icon_name,
         values: @icon_name_options,
         required: true
  ```
  """
  @doc type: :macro
  defmacro __using__(_opts) do
    quote do
      import Phlegethon.Components.Icon, only: [icon: 1]

      @icon_kind_options unquote(@icon_kind_options)
      @icon_name_options unquote(@icon_name_options)
    end
  end

  @doc """
  Renders an icon. Currently it simply wraps `Heroicons`, but adds conveniences (like a dynamic icon name) and overridable defaults.

  > #### Tip {: .info}
  >
  > See the [Heroicons website](https://heroicons.com/) to preview/search the available icons.
  >
  > **Note:** The names from the website will be dashed, but the names in the component will be underscored atoms.
  > For example: `academic-cap` becomes `:academic_cap`

  Additionally, there are long-term plans to add more icon libraries, so this is a worthy abstraction for several features.

  ## Examples

  ```heex
  <.icon name={:arrow_left} />
  ```
  ```heex
  <.icon name={:arrow_right} kind={:mini} class="block" />
  ```
  """
  @doc type: :component

  overridable :class, :class, required: true

  overridable :kind, :atom,
    required: true,
    values: @icon_kind_options,
    doc: "The icon kind"

  attr :name, :atom,
    required: true,
    values: @icon_name_options,
    doc: "The icon name"

  attr :rest, :global,
    doc: "The arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  def icon(assigns) do
    kind = assigns[:kind]
    class = assigns[:class]

    assigns =
      assigns
      |> assign(:rest, Map.put(assigns[:rest], :class, class))
      |> assign(:outline, kind == :outline)
      |> assign(:solid, kind == :solid)
      |> assign(:mini, kind == :mini)

    apply(Heroicons, assigns.name, [assigns])
  end
end
