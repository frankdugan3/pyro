defmodule Pyro.Design.Context do
  @moduledoc false

  use Pyro.Dsl.Entity,
    name: :context,
    args: [:name],
    describe: """
    A DTCG resolver-module context — a named slot inside a modifier.

    Each context holds the token overrides that apply when this context
    is selected at resolver runtime. Children are the usual Design
    vocabulary — tokens, groups, and nested modifiers.

        modifier :color_mode do
          default :light

          context :light do
            color :bg, "#fff"
          end

          context :dark do
            color :bg, "#000"
          end
        end
    """,
    entities: [children: [Pyro.Design.Group, Pyro.Design.Token]],
    imports: [Pyro.Design.Macros],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "Context name (e.g. `:light`, `:dark`)."
      ],
      description: [type: :string, doc: "DTCG `$description`."],
      extensions: [
        type: {:map, :string, :any},
        default: %{},
        doc: "DTCG `$extensions` — vendor-namespaced metadata."
      ]
    ]
end
