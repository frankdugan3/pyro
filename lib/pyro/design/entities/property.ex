defmodule Pyro.Design.Property do
  @moduledoc false

  use Pyro.Dsl.Entity,
    name: :property,
    args: [:name, :value],
    describe: """
    A single CSS declaration inside a `selector` block.

        selector "html, body" do
          property "margin", "0"
          property "color", "$color.brand.500"
        end

    `name` is the CSS property name. `value` is the CSS value;
    `$token.path` references are resolved against the design's token
    tree before emission.
    """,
    schema: [
      name: [
        type: :string,
        required: true,
        doc: "CSS property name."
      ],
      value: [
        type: :string,
        required: true,
        doc: "CSS value. `$token.path` references resolve against the design's token tree."
      ]
    ]
end
