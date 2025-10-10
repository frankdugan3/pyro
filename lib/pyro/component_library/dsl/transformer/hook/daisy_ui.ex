defmodule Pyro.ComponentLibrary.Dsl.Transformer.Hook.DaisyUI do
  @moduledoc """
  A component transformer that applies DaisyUI styles.
  """

  use Pyro.ComponentLibrary.Dsl.Transformer.Hook

  alias Pyro.ComponentLibrary.Dsl.Block
  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Pyro.ComponentLibrary.Dsl.Render
  alias Pyro.ComponentLibrary.Dsl.Variant
  alias Pyro.HEEx.AST.Attribute
  alias Pyro.HEEx.AST.ParseError

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
    base_class = get_base_class(component, prefix)

    context =
      context
      |> Map.put(:component, component)
      |> Map.put(:base_class, base_class)

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
          [inspect(context.base_class) | acc]

        %Attribute{name: "pyro-variant", type: :string, value: value} = attr, acc ->
          name = String.to_existing_atom(value)

          case Enum.find(
                 context.component.assigns,
                 &(&1.name == name && __MODULE__ == &1.hook)
               ) do
            %Variant{default: nil, type: :atom} ->
              [~s[@#{value} && "#{context.base_class}-\#{@#{value}}"] | acc]

            %Variant{default: default, type: :atom} when is_atom(default) ->
              [~s["#{context.base_class}-\#{@#{value}}"] | acc]

            %Variant{default: nil, type: :string} ->
              ["@#{value} && #{inspect(context.base_class <> "-")} <> @#{value}" | acc]

            %Variant{default: default, type: :string} when is_binary(default) ->
              ["#{inspect(context.base_class <> "-")} <> @#{value}" | acc]

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

  defp get_base_class(component, prefix) do
    case Enum.find(component.blocks, &(&1.hook == __MODULE__)) do
      %Block{meta: %{base_class: base_class}} -> "#{prefix}#{base_class}"
      _ -> "#{prefix}#{component.name}"
    end
  end
end
