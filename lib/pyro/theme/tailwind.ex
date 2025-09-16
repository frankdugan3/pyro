defmodule Pyro.Theme.Tailwind do
  @moduledoc false

  # @color_type {:or,
  #              [
  #                :string,
  #                {:one_of, ~w[black white]a},
  #                {:tuple,
  #                 [
  #                   {:one_of, ~w[
  #                     gray neutral stone zinc slate
  #                     red rose
  #                     yellow amber orange
  #                     green lime emerald
  #                     blue teal cyan sky
  #                     purple indigo violet
  #                     pink fuchsia
  #                   ]a},
  #                   {:one_of, [50] ++ Enum.to_list(100..900//100) ++ [950]}
  #                 ]}
  #              ]}
  #
  # @color %{
  #   args: [:name, :light, {:optional, :dark}],
  #   describe: """
  #   Implement a color token for a theme property.
  #
  #   The value can either refer to the built-in Tailwind palette (e.g. `:white`, `{:red, 500}`) or a string with any valid CSS color value.
  #   """,
  #   name: :color,
  #   schema: [
  #     name: [type: :atom, required: true],
  #     light: [type: @color_type, required: true, doc: "color for light scheme"],
  #     dark: [type: @color_type, doc: "color for dark scheme (defaults to light scheme)"]
  #   ],
  #   target: __MODULE__.Color
  # }
end
