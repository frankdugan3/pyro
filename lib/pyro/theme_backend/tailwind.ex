defmodule Pyro.ThemeBackend.Tailwind do
  @moduledoc false

  defmodule Color do
    @moduledoc false
    defstruct [:name, :light, :dark]
  end

  @color_type {:or,
               [
                 :string,
                 {:one_of, ~w[black white]a},
                 {:tuple,
                  [
                    {:one_of, ~w[
                      gray neutral stone zinc slate
                      red rose
                      yellow amber orange
                      green lime emerald
                      blue teal cyan sky
                      purple indigo violet
                      pink fuchsia
                    ]a},
                    {:one_of, [50] ++ Enum.to_list(100..900//100) ++ [950]}
                  ]}
               ]}

  @color %Spark.Dsl.Entity{
    name: :color,
    describe: """
    Implement a color token for a theme property.

    The value can either refer to the built-in Tailwind palette (e.g. `:white`, `{:red, 500}`) or a string with any valid CSS color value.
    """,
    schema: [
      name: [type: :atom, required: true],
      light: [type: @color_type, required: true, doc: "color for light scheme"],
      dark: [type: @color_type, doc: "color for dark scheme (defaults to light scheme)"]
    ],
    target: __MODULE__.Color,
    args: [:name, :light, {:optional, :dark}]
  }

  defmodule Variant do
    @moduledoc false
    defstruct [:name, :tokens]
  end

  @variant %Spark.Dsl.Entity{
    name: :variant,
    describe: """
    Implement a varient for a theme property.
    """,
    schema: [
      name: [
        type: :atom
      ]
    ],
    target: __MODULE__.Variant,
    args: [:name],
    entities: [tokens: [@color]]
  }

  defmodule Property do
    @moduledoc false
    defstruct [:name, :variants]
  end

  @property %Spark.Dsl.Entity{
    name: :property,
    describe: """
    Implement a theme property.
    """,
    schema: [
      name: [type: :atom]
    ],
    target: __MODULE__.Property,
    args: [:name],
    entities: [variants: [@variant]]
  }

  @tailwind %Spark.Dsl.Section{
    name: :tailwind,
    describe: """
    Tailwind theme backend.
    """,
    entities: [@property]
  }

  @transformers []
  @verifiers []
  @sections [@tailwind]

  @behaviour Pyro.ThemeBackend

  use Spark.Dsl.Extension,
    sections: @sections,
    transformers: @transformers,
    verifiers: @verifiers
end
