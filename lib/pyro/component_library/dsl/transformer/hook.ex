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

  def pop_render_attrs(render, pattern, context) do
    transform_heex(
      render,
      fn content, context ->
        case HeexParser.parse(content) do
          {:ok, ast} ->
            {ast, attrs} = HeexParser.pop_attributes(ast, pattern)
            context =
              Map.update(context, :popped_attrs, [attrs], fn popped_attrs ->
                popped_attrs ++ [attrs]
              end)

            {ast, context}

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
      end,
      context
    )
  end

  def transform_heex(%{expr: expr} = entity, transformer, context)
      when is_function(transformer, 2) do
    {updated_expr, context} =
      Macro.prewalk(expr, context, fn
        {:sigil_H, meta, [{:<<>>, bin_meta, [content]}, modifiers]}, context ->
          {transformed_content, context} = transformer.(content, context)
          {{:sigil_H, meta, [{:<<>>, bin_meta, [transformed_content]}, modifiers]}, context}

       node, acc ->
         {node, acc}
      end)

    {%{entity | expr: updated_expr}, context}
  end
end
