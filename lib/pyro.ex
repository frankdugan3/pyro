defmodule Pyro do
  @moduledoc """
  > Compose extensible components for Phoenix.

  - For a summary about what Pyro is, check out the [About](about.html) page.
  - To install and learn how it all fits together, follow the [Get Started](get-started.html) guide.
  - For DSL documentation, check out [Pyro Component DSL](dsl-pyro-component.html).

  #### Examples

  ```elixir
  defmodule MyAppWeb.CoreComponents do
    use Pyro, component_libraries: [
      PyroComponents,
      PyroComponents.Defaults.HeadlessBem
    ]

    variables %{
      prefix: "my-app-"
    }
  end
  ```
  """
  use Spark.Dsl,
    default_extensions: [
      extensions: [Pyro.Component]
    ],
    many_extension_kinds: [
      :component_libraries
    ],
    extension_kind_types: [
      component_libraries: {:wrap_list, {:spark, Pyro.Component}}
    ],
    opt_schema: [
      component_output_path: [
        type: :string,
        doc:
          "The path to use for storing generated component files. It is relative to the current working directory."
      ],
      js_output_path: [
        type: :string,
        default: "assets/js",
        doc:
          "The path to use for storing the generated JS file. It is relative to the current working directory."
      ],
      css_output_path: [
        type: :string,
        default: "assets/css",
        doc:
          "The path to use for storing generated CSS files. It is relative to the current working directory."
      ],
      css_strategy: [
        type: :atom,
        doc: "The CSS strategy to use for all components."
      ],
      css_normalizer: [
        type: {:fun, 1},
        default: &Function.identity/1,
        doc: "The fallback CSS normalizer. See [Class Variants](class-variants.html)."
      ],
      library?: [
        type: :boolean,
        default: false,
        doc: "Mark module as a library. Disables finalizing code generation and validations."
      ],
      build_components?: [
        type: :boolean,
        default: true,
        doc:
          "Build the components declared in the DSL and attach them to the module. Automatically disabled if `library?: true`."
      ],
      build_live_components?: [
        type: :boolean,
        default: true,
        doc:
          "Build the live components declared in the DSL and attach them to the module. Automatically disabled if `library?: true`."
      ],
      implements_css_strategies: [
        type: {:wrap_list, :atom},
        default: [],
        doc: "List of CSS strategies to verify are implmented."
      ]
    ]

  @doc false
  @impl Spark.Dsl
  def handle_opts(opts) do
    library? = opts[:library?]
    build_components? = if(library?, do: false, else: opts[:build_components?])
    build_live_components? = if(library?, do: false, else: opts[:build_live_components?])
    css_output_path = if(library?, do: nil, else: opts[:css_output_path])
    js_output_path = if(library?, do: nil, else: opts[:js_output_path])
    component_libraries = opts[:component_libraries]

    css_strategy =
      opts[:css_strategy] ||
        Enum.reduce(component_libraries, nil, fn lib, acc ->
          case Spark.Dsl.Extension.get_persisted(lib, :css_strategy) do
            nil -> acc
            strategy -> strategy
          end
        end)

    quote bind_quoted: [
            library?: library?,
            build_components?: build_components?,
            build_live_components?: build_live_components?,
            component_libraries: component_libraries,
            component_output_path: opts[:component_output_path],
            js_output_path: js_output_path,
            css_output_path: css_output_path,
            css_strategy: css_strategy,
            css_normalizer: opts[:css_normalizer],
            implements_css_strategies: opts[:implements_css_strategies]
          ] do
      Enum.each(component_libraries, fn component_library ->
        unless Spark.Dsl.Extension.get_persisted(component_library, :library?) do
          raise """
          Configuration Error in #{inspect(__MODULE__)}:

              Option: :component_libraries

              Module #{inspect(component_library)} is not a library: Only libraries can be merged.
          """
        end
      end)

      @persist {:library?, library?}
      @persist {:build_components?, build_components?}
      @persist {:build_live_components?, build_live_components?}
      @persist {:component_output_path, component_output_path}
      @persist {:js_output_path, js_output_path}
      @persist {:css_output_path, css_output_path}
      @persist {:css_strategy, css_strategy}
      @persist {:implements_css_strategies, implements_css_strategies}
      @persist {:css_normalizer, css_normalizer}
    end
  end

  @doc false
  @impl Spark.Dsl
  def handle_before_compile(_opts) do
    quote do
      @after_compile {__MODULE__, :__generate_templates__}

      def __generate_templates__(env, _bytecode) do
        # Generators only run if their path option is set
        Mix.Tasks.Pyro.Generators.Css.generate(env.module)
        Mix.Tasks.Pyro.Generators.JS.generate(env.module)
        Mix.Tasks.Pyro.Generators.Components.generate(env.module)

        if Pyro.Info.build_components?(env.module) do
          component_code =
            Mix.Tasks.Pyro.Generators.Components.gen_module(env.module, embedded?: true)

          Code.eval_string(component_code)
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
