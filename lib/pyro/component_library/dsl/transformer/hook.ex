defmodule Pyro.ComponentLibrary.Dsl.Transformer.Hook do
  @moduledoc """
  Behaviour for implementing component transformers.
  """

  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Pyro.ComponentLibrary.Dsl.Render
  alias Pyro.HEEx
  alias Pyro.HEEx.AST

  @type component :: %Component{} | %LiveComponent{}

  @callback transform_component(component(), map()) :: component()

  def pop_render_attrs(%Render{} = render, pattern, context) do
    transform_heex(
      render,
      fn %AST{} = ast, context ->
        ast = HEEx.pop_attributes(ast, pattern)

        attrs =
          Enum.map(ast.context.popped_attributes, fn {path, attr} ->
            {context.sigil_H_index, path, attr}
          end)

        context =
          Map.update(context, :popped_attributes, attrs, fn popped_attributes ->
            popped_attributes ++ attrs
          end)

        {ast, context}
      end,
      context
    )
  end

  def transform_heex(%Render{expr: expr} = entity, transformer, context)
      when is_function(transformer, 2) do
    {updated_expr, context} =
      Macro.prewalk(expr, context, fn
        {:sigil_H, meta, [{:<<>>, string_meta, [content]}, modifiers]}, context ->
          context = Map.update(context, :sigil_H_index, 0, &(&1 + 1))

          opts = [
            file: entity.__spark_metadata__.anno[:file],
            line: string_meta[:line] + 1,
            source_offset: meta[:line],
            indentation: string_meta[:indentation] || 0
          ]

          ast = AST.parse!(content, opts)
          {transformed_ast, context} = transformer.(ast, context)
          transformed_content = AST.encode(transformed_ast)

          {{:sigil_H, meta, [{:<<>>, string_meta, [transformed_content]}, modifiers]}, context}

        node, acc ->
          {node, acc}
      end)

    {%{entity | expr: updated_expr}, context}
  end
end
