defmodule Pyro.Design.Raw do
  @moduledoc false

  use Pyro.Dsl.Entity,
    name: :raw,
    args: [:css],
    describe: """
    Raw CSS string emitted into `@layer base` verbatim, after
    `$token.path` reference resolution. Use only for rules that the
    structured `selector` entity cannot express — primarily at-rules
    whose body itself contains rules (`@keyframes`, `@supports`,
    conditional `@media` blocks). Prefer `selector` for everything
    else; `raw` skips per-property validation.

        config do
          base_layer do
            raw \"\"\"
            @keyframes flash {
              0% { background: $color.brand.500/50; }
              100% { background: transparent; }
            }
            \"\"\"
          end
        end
    """,
    schema: [
      css: [
        type: :string,
        required: true,
        doc: "Raw CSS body. `$token.path` references resolve via the design's namespace."
      ]
    ]
end
