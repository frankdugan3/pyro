defmodule Pyro.Design.Selector do
  @moduledoc false

  use Pyro.Dsl.Entity,
    name: :selector,
    args: [:selector],
    describe: """
    A CSS rule — one or more selectors and a declaration block — used
    inside the `config.base_layer` section to author rules emitted
    into `@layer base` of the generated CSS.

        config do
          base_layer do
            selector ["html", "body"] do
              property "margin", "0"
            end
          end
        end

    Pass a single string for one selector or a list of strings to share
    a declaration block across selectors. Property values may reference
    design tokens via `$token.path`, which the writer resolves before
    emission.
    """,
    entities: [properties: [Pyro.Design.Property]],
    schema: [
      selector: [
        type: {:wrap_list, :string},
        required: true,
        doc: "One or more CSS selectors that share this declaration block."
      ]
    ]
end
