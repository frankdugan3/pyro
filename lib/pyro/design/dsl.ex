defmodule Pyro.Design.Dsl do
  @moduledoc false

  @design_entity_modules [
    Pyro.Design.Group,
    Pyro.Design.Modifier,
    Pyro.Design.Token
  ]

  use Spark.Dsl.Extension,
    sections: [
      %Spark.Dsl.Section{
        name: :config,
        describe: """
        Pyro-specific configuration that complements the DTCG token tree.
        """,
        schema: [
          namespace: [
            type: :string,
            required: true,
            doc: ~s{Prefix for generated CSS custom property names (e.g., `"pyro"` → `--pyro-*`).}
          ],
          tailwind_preamble: [
            type: :string,
            doc:
              "Raw CSS for Tailwind custom variants. Included before the auto-generated `@theme` block when `support_tailwind?: true` on the design module."
          ]
        ],
        sections: [
          %Spark.Dsl.Section{
            name: :base_layer,
            describe: """
            CSS rules for `@layer base`. Rendered when `manage_base_layer?: true`.
            """,
            entities: [Pyro.Design.Selector.__entity__(), Pyro.Design.Raw.__entity__()]
          }
        ]
      },
      %Spark.Dsl.Section{
        name: :design,
        describe: """
        A DTCG 2025.10 token tree.

        Authors use macros from `Pyro.Design.Macros` (`color`, `dimension`,
        `shadow`, `typography`, `ref`, `root`, …) — values are parsed
        eagerly at compile time. See `Pyro.Design.Macros` for the full
        catalog with executable examples. Groups nest recursively.
        Modifiers with their context children model DTCG resolver
        modifiers.
        """,
        imports: [Pyro.Design.Macros],
        entities: Enum.map(@design_entity_modules, & &1.__entity__())
      },
      %Spark.Dsl.Section{
        name: :icons,
        describe: "Named icons (Pyro-specific; non-DTCG).",
        entities: [Pyro.Design.Icon.__entity__()],
        imports: [Pyro.Sigils]
      }
    ],
    transformers: [
      Pyro.Design.Transformers.MergeSources,
      Pyro.Design.Transformers.MergeDuplicateContexts,
      Pyro.Design.Transformers.ValidateTree,
      Pyro.Design.Transformers.BuildTokenTree,
      Pyro.Design.Transformers.GenerateDocs
    ]

  @doc "Modules that back the `:design` section's entities."
  def design_entity_modules, do: @design_entity_modules
end
