defmodule Pyro.Design.Value do
  @moduledoc false

  # Shared helpers consumed by `Pyro.Design.Macros`, the `:type`
  # schema on tokens, and the per-type parsing modules under
  # `Pyro.Design.Value.*`.

  @types ~w[color dimension font_family font_weight duration cubic_bezier number
            stroke_style border transition shadow gradient typography]a

  # CSS Fonts Module Level 4 weight aliases — integers per the spec.
  @font_weight_aliases %{
    thin: 100,
    hairline: 100,
    extra_light: 200,
    ultra_light: 200,
    light: 300,
    normal: 400,
    regular: 400,
    book: 400,
    medium: 500,
    semi_bold: 600,
    demi_bold: 600,
    bold: 700,
    extra_bold: 800,
    ultra_bold: 800,
    black: 900,
    heavy: 900,
    extra_black: 950,
    ultra_black: 950
  }

  @doc "The 13 DTCG `$type` atoms supported by the DSL."
  @spec types() :: [atom()]
  def types, do: @types

  @doc "CSS font-weight aliases mapped to their numeric weight."
  @spec font_weight_aliases() :: %{atom() => integer()}
  def font_weight_aliases, do: @font_weight_aliases
end
