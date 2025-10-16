defmodule Pyro.ComponentLibrary.Dsl.Transformer.Hook.DaisyUI do
  @moduledoc """
  A component transformer that applies DaisyUI styles.
  """
  use Pyro.ComponentLibrary.Dsl.Transformer.Hook

  alias Pyro.ComponentLibrary.Dsl.Block, as: DslBlock
  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Pyro.ComponentLibrary.Dsl.Render
  alias Pyro.ComponentLibrary.Dsl.Variant
  alias Pyro.HEEx.AST.Attribute
  alias Pyro.HEEx.AST.ParseError
  alias Spark.Dsl.Entity
  alias Spark.Dsl.Transformer
  alias Spark.Error.DslError

  defmodule Config do
    @moduledoc """
    Configure the DaisyUI transformer hook.
    """
    @type t :: %__MODULE__{
            prefix: String.t(),
            tailwind_prefix: String.t() | nil
          }

    # quokka:sort
    defstruct [:tailwind_prefix, prefix: ""]
  end

  defmodule Block do
    @moduledoc """
    Configure component block for DaisyUI transformer hook.
    """
    @type t :: %__MODULE__{
            component_class: String.t() | nil
          }

    # quokka:sort
    defstruct [:component_class]
  end

  @impl true
  def transform_component(%LiveComponent{} = live_component, context) do
    live_component
    |> do_transform(context)
    |> Map.update!(
      :components,
      &Enum.map(&1, fn component ->
        transform_component(component, context)
      end)
    )
  end

  def transform_component(%Component{} = component, context) do
    do_transform(component, context)
  end

  defp do_transform(component, context) do
    tailwind_prefix =
      (context.config.tailwind_prefix && context.config.tailwind_prefix <> ":") || ""

    block_config =
      case Pyro.Info.component_block(component, __MODULE__) do
        %DslBlock{meta: %Block{} = meta} ->
          meta

        %DslBlock{meta: meta} = entity ->
          file = Transformer.get_persisted(context.dsl, :file)
          location = Entity.anno(entity)

          raise DslError,
            file: file,
            location: location,
            path: context.path,
            message: "%#{__MODULE__.Block}{} required for Block.meta, got #{inspect(meta)}"

        nil ->
          %Block{}
      end
      |> Map.update!(:component_class, fn
        class when is_binary(class) and class != "" ->
          tailwind_prefix <> context.config.prefix <> class

        _ ->
          class =
            component.name
            |> Atom.to_string()
            |> String.replace("_", "-")

          tailwind_prefix <> context.config.prefix <> class
      end)

    context =
      context
      |> Map.put(:component, component)
      |> Map.put(:block_config, block_config)

    component
    |> Map.update!(:render, fn renders ->
      for %Render{} = render <- renders do
        {render, _context} =
          transform_render_attrs(render, [~r"^pyro-", "class"], &transform_attrs/2, context)

        render
      end
    end)
  end

  defp transform_attrs(attrs, context) do
    expr =
      attrs
      |> Enum.reduce([], fn
        %Attribute{name: "class", type: :expression, value: value}, acc ->
          [value | acc]

        %Attribute{name: "class", type: :string, value: value}, acc ->
          [inspect(value) | acc]

        %Attribute{name: "pyro-block"}, acc ->
          [inspect(context.block_config.component_class) | acc]

        %Attribute{name: "pyro-variant", type: :string, value: value} = attr, acc ->
          name = String.to_existing_atom(value)

          case Enum.find(
                 context.component.assigns,
                 &(&1.name == name && __MODULE__ == &1.hook)
               ) do
            %Variant{default: nil, type: :atom} ->
              [~s[@#{value} && "#{context.block_config.component_class}-\#{@#{value}}"] | acc]

            %Variant{default: default, type: :atom} when is_atom(default) ->
              [~s["#{context.block_config.component_class}-\#{@#{value}}"] | acc]

            %Variant{default: nil, type: :string} ->
              [
                "@#{value} && #{inspect(context.block_config.component_class <> "-")} <> @#{value}"
                | acc
              ]

            %Variant{default: default, type: :string} when is_binary(default) ->
              ["#{inspect(context.block_config.component_class <> "-")} <> @#{value}" | acc]

            nil ->
              opts = context.ast.opts

              raise ParseError,
                file: opts[:file],
                indentation: opts[:indentation],
                source_offset: opts[:source_offset],
                source: context.ast.source,
                line: attr.line,
                column: attr.column,
                message: "variant #{inspect(name)} is undefined",
                pretty?: opts[:pretty_errors?]
          end

        _, acc ->
          acc
      end)
      |> Enum.join(", ")

    [
      %Attribute{
        delimiter: nil,
        name: "class",
        type: :expression,
        value: "[" <> expr <> "]"
      }
    ]
  end
end
