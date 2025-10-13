defmodule Pyro.ComponentLibrary.Dsl.Transformer.Hook.BEM do
  @moduledoc """
  A component transformer that applies standard BEM classes.
  """
  use Pyro.ComponentLibrary.Dsl.Transformer.Hook

  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Pyro.ComponentLibrary.Dsl.Render
  alias Pyro.ComponentLibrary.Dsl.Variant
  alias Pyro.HEEx.AST.Attribute
  alias Pyro.HEEx.AST.ParseError

  defmodule Config do
    @moduledoc """
    Configure the BEM transformer hook.
    """
    @type t :: %__MODULE__{}

    # quokka:sort
    defstruct []
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
    prefix = Pyro.Info.css_prefix(context.dsl)
    component_name = bem_component_name(component, prefix)

    context =
      context
      |> Map.put(:component, component)
      |> Map.put(:component_name, component_name)

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
          [inspect(context.component_name) | acc]

        %Attribute{name: "pyro-variant", type: :string, value: value} = attr, acc ->
          name = String.to_existing_atom(value)

          case Enum.find(
                 context.component.assigns,
                 &(&1.name == name && __MODULE__ == &1.hook)
               ) do
            %Variant{default: nil, type: :atom} ->
              [~s[@#{value} && "#{context.component_name}--\#{@#{value}}"] | acc]

            %Variant{default: default, type: :atom} when is_atom(default) ->
              [~s["#{context.component_name}--\#{@#{value}}"] | acc]

            %Variant{default: nil, type: :string} ->
              ["@#{value} && #{inspect(context.component_name <> "--")} <> @#{value}" | acc]

            %Variant{default: default, type: :string} when is_binary(default) ->
              ["#{inspect(context.component_name <> "--")} <> @#{value}" | acc]

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

  defp bem_component_name(%Component{} = component, prefix) do
    "#{prefix}#{component.name}"
    |> String.downcase()
    |> String.replace("_", "-")
  end
end
