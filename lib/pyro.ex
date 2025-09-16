defmodule Pyro do
  @moduledoc """
  > Compose extensible components for Phoenix.

  - Import/extend component libraries
  - Add your own components
  - For a summary about what Pyro is, check out the [About](about.html) page.
  - To install and learn how it all fits together, follow the [Get Started](get-started.html) guide.
  - For DSL documentation, check out [Component Library DSL](dsl-pyro-componentlibrary.html).

  #### Examples

  ```elixir
  defmodule MyAppWeb.CoreComponents do
    use Pyro, component_libraries: [PyroComponents]
  end
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
    component_output_path = opts[:component_output_path]
    css_output_path = opts[:css_output_path]

    quote bind_quoted: [
            component_output_path: component_output_path,
            css_output_path: css_output_path
          ] do
      @persist {:component_output_path, component_output_path}
      @persist {:css_output_path, css_output_path}
    end
  end

  @doc false
  @impl Spark.Dsl
  def handle_before_compile(_opts) do
    quote do
      #   @after_compile {__MODULE__, :__generate_templates__}
      #
      #   def __generate_templates__(env, _bytecode) do
      #     # Generators only run if their path option is set
      #     Mix.Tasks.Pyro.Generators.Css.generate(env.module)
      #     Mix.Tasks.Pyro.Generators.Components.generate(env.module)
      #
      #     if Pyro.Info.build_components?(env.module) do
      #       component_code =
      #         Mix.Tasks.Pyro.Generators.Components.gen_module(env.module, embedded?: true)
      #
      #       Code.eval_string(component_code)
      #     end
      #   end
      #
      #   defmacro __using__(_opts) do
      #     Code.ensure_compiled(__MODULE__.Components)
      #
      #     quote do
      #       import unquote(__MODULE__).Components
      #     end
      #   end
    end
  end
end
