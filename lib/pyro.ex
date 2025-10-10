defmodule Pyro do
  @moduledoc """
  > Compose extensible components for Phoenix.

  - Import/extend component libraries
  - Add your own components
  - For a summary about what Pyro is, check out the [About](about.html) page.
  - To install and learn how it all fits together, follow the [Get Started](get-started.html) guide.
  - For DSL documentation, check out [Component Library DSL](dsl-pyro-blocklibrary.html).

  #### Examples

  ```elixir
  defmodule MyAppWeb.CoreComponents do
    use Pyro, component_libraries: [PyroComponents]
  end
  ```
  """

  use Spark.Dsl,
    default_extensions: [
      extensions: [__MODULE__.ComponentLibrary.Dsl]
    ],
    many_extension_kinds: [:component_libraries, :theme_backends],
    extension_kind_types: [
      component_libraries: {:wrap_list, {:spark, Pyro.ComponentLibrary}}
    ],
    opt_schema: [
      debug?: [
        type: :boolean,
        default: false,
        doc: "If true, will output debug information for components."
      ],
      transformer_hook: [
        type: {:behaviour, __MODULE__.ComponentLibrary.Dsl.Transformer.Hook},
        required: true,
        doc: """
        The transformer library to use.
        """
      ],
      merge_libraries?: [
        type: :boolean,
        default: false,
        doc:
          "If true, imported components from different libraries will be merged in order of their import. If false, duplicate names will raise a compilation error."
      ],
      component_output_path: [
        type: :string,
        doc:
          "The path to use for storing generated component files. It is relative to the current working directory."
      ],
      css_output_path: [
        type: :string,
        default: "assets/css",
        doc:
          "The path to use for storing generated CSS files. It is relative to the current working directory."
      ]
    ]

  @doc false
  @impl Spark.Dsl
  def handle_opts(opts) do
    transformer_hook = opts[:transformer_hook]
    component_output_path = opts[:component_output_path]
    css_output_path = opts[:css_output_path]
    merge_libraries? = opts[:merge_libraries?]

    quote bind_quoted: [
            transformer_hook: transformer_hook,
            component_output_path: component_output_path,
            component_output_path: component_output_path,
            css_output_path: css_output_path,
            merge_libraries?: merge_libraries?
          ] do
      @persist {:transformer_hook, transformer_hook}
      @persist {:component_output_path, component_output_path}
      @persist {:css_output_path, css_output_path}
      @persist {:merge_libraries?, merge_libraries?}
    end
  end

  @doc false
  @impl Spark.Dsl
  def handle_before_compile(opts) do
    quote do
      @external_resource "lib/mix/tasks/generators/components.ex"
      @external_resource "lib/mix/tasks/generators/css.ex"

      @after_compile {__MODULE__, :__generate_templates__}

      def __generate_templates__(env, _bytecode) do
        Mix.Tasks.Pyro.Generators.CSS.generate(env.module)
        component_code = Mix.Tasks.Pyro.Generators.Components.generate(env.module)

        if !Pyro.Info.component_output_path(env.module) do
          Code.eval_string(component_code)
        end

        if unquote(opts[:debug?]) do
          ("\n" <> component_code)
          |> Autumn.highlight!(language: "elixir", formatter: :terminal)
          |> IO.puts()
        end
      end

      defmacro __using__(_opts) do
        Code.ensure_compiled(__MODULE__.Components)

        quote do
          import unquote(__MODULE__).Components
        end
      end
    end
  end
end
