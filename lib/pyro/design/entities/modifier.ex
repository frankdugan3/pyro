defmodule Pyro.Design.Modifier do
  @moduledoc false

  use Pyro.Dsl.Entity,
    name: :modifier,
    args: [:name],
    describe: """
    A DTCG resolver-module modifier — a named conditional layer with two
    or more **contexts**, each supplying token overrides for a specific
    condition (e.g. `light` / `dark` color modes, `compact` / `comfortable`
    density).

        modifier :color_mode do
          description "Light vs dark."
          default :light

          context :light do
            color :bg, "#fff"
          end

          context :dark do
            color :bg, "#000"
          end
        end

    Optionally names a `default` context to apply when the resolver input
    omits this modifier key. The Design compiler persists these under
    `:design_modifiers`.
    """,
    entities: [contexts: [Pyro.Design.Context]],
    imports: [Pyro.Design.Macros],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "Modifier name (e.g. `:color_mode`, `:density`)."
      ],
      description: [type: :string, doc: "DTCG `$description`."],
      default: [
        type: :atom,
        doc: "Name of the context to apply when the resolver input omits this modifier key."
      ],
      extensions: [
        type: {:map, :string, :any},
        default: %{},
        doc: "DTCG `$extensions` — vendor-namespaced metadata."
      ]
    ]
end
