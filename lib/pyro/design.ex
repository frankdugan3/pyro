defmodule Pyro.Design do
  @moduledoc """
  Define a design system specification.

  A design system declares the complete DTCG token vocabulary for a
  project — groups, tokens, modifiers (with contexts). It also defines
  icons.

  ## Composition — `sources:`

  A design module can compose others via the `:sources` option. Sources
  merge in declared order, following DTCG Resolver's `resolutionOrder`
  semantics — later sources override earlier ones at equal paths, and
  this module's own declarations are applied last.

      defmodule MyApp.Dark do
        use Pyro.Design, sources: [MyApp.Base]

        design do
          color :brand, "#000000"   # overrides MyApp.Base's :brand
        end
      end

  Module sources merge natively. String-path sources (for DTCG JSON
  files) are accepted by the schema but raise `"not yet implemented"`
  at compile until the JSON loader lands.

  [Design DSL documentation](dsl-pyro-design.html)
  """

  use Spark.Dsl,
    opt_schema: [
      sources: [
        type: {:list, {:or, [:atom, :string]}},
        default: [],
        doc: """
        Ordered list of design sources to merge before this module's own
        declarations. Each item is either a compiled `Pyro.Design` module
        (inline source) or a string path to a DTCG JSON file. Per DTCG Resolver
        `resolutionOrder` semantics, later sources override earlier ones
        at equal paths; this module's own declarations are applied last.
        """
      ],
      css_output: [
        type: {:or, [{:literal, nil}, :string]},
        doc:
          "Output path for the generated CSS custom-property file. Output generation is currently deferred — the option is persisted but no file is written."
      ],
      json_output: [
        type: {:or, [{:literal, nil}, :string]},
        doc: "Output path for the generated W3C DTCG JSON file."
      ],
      support_tailwind?: [
        type: :boolean,
        default: false,
        doc:
          "When `true`, the (future) CSS generator emits Tailwind v4 `@theme` directives alongside the `:root` block."
      ],
      manage_base_layer?: [
        type: :boolean,
        default: false,
        doc:
          "When `true`, the (future) CSS generator emits a `@layer base` block from the `config > base_layer` section."
      ]
    ],
    default_extensions: [extensions: [Pyro.Design.Dsl]]

  @type t :: module

  @impl Spark.Dsl
  def handle_opts(opts) do
    sources = opts[:sources] || []
    css_output = opts[:css_output]
    json_output = opts[:json_output]
    support_tailwind? = opts[:support_tailwind?]
    manage_base_layer? = opts[:manage_base_layer?]

    quote bind_quoted: [
            sources: sources,
            css_output: css_output,
            json_output: json_output,
            support_tailwind?: support_tailwind?,
            manage_base_layer?: manage_base_layer?
          ] do
      @persist {:design_sources_raw, sources}

      for source <- sources, is_atom(source) do
        @external_resource to_string(source.__info__(:compile)[:source])
      end

      @persist {:css_output, css_output}
      @persist {:json_output, json_output}
      @persist {:support_tailwind?, support_tailwind?}
      @persist {:manage_base_layer?, manage_base_layer?}
    end
  end

  @impl Spark.Dsl
  def handle_before_compile(_opts) do
    quote do
      design_docs = Spark.Dsl.Extension.get_persisted(__MODULE__, :design_docs)

      if design_docs do
        case Module.get_attribute(__MODULE__, :moduledoc) do
          {line, doc} when is_binary(doc) ->
            Module.put_attribute(__MODULE__, :moduledoc, {line, doc <> "\n\n" <> design_docs})

          nil ->
            Module.put_attribute(__MODULE__, :moduledoc, {0, design_docs})

          _ ->
            :ok
        end
      end

      @after_compile {Pyro.Design, :__write_outputs__}
    end
  end

  @doc false
  def __write_outputs__(env, _bytecode) do
    Pyro.Design.JSON.Writer.write(env.module)
    Pyro.Design.CSS.Writer.write(env.module)
    :ok
  end
end
