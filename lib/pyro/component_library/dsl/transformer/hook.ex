defmodule Pyro.ComponentLibrary.Dsl.Transformer.Hook do
  @moduledoc """
  Behaviour for implementing component transformers.
  """

  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Pyro.HeexParser
  alias Spark.Error.DslError

  @type component :: %Component{} | %LiveComponent{}
  @callback transform_component(component(), map()) :: component()

  def transform_sigil_h_content(%{expr: expr} = entity, transformer)
      when is_function(transformer, 1) do
    updated_expr =
      Macro.postwalk(expr, fn
        {:sigil_H, meta, [{:<<>>, bin_meta, [content]}, modifiers]} when is_binary(content) ->
          transformed_content = transformer.(content)
          {:sigil_H, meta, [{:<<>>, bin_meta, [transformed_content]}, modifiers]}

        node ->
          node
      end)

    %{entity | expr: updated_expr}
  end

  def transform_render(render, context) do
    transform_sigil_h_content(render, fn content ->
      case HeexParser.parse(content) do
        {:ok, ast} ->
          ast
          |> HeexParser.pop_attributes("pyro-*")

        {:error, error} ->
          raise DslError.exception(
                  module: context.module,
                  path: context.path,
                  message: """
                  Unable to parse ~H for render function in component #{inspect(context.component.name)}

                  #{error}
                  """
                )
      end
    end)
  end
end
