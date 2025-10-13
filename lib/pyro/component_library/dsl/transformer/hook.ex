defmodule Pyro.ComponentLibrary.Dsl.Transformer.Hook do
  @moduledoc """
  Behaviour for implementing component transformers.

  The appropriate way to use this feature is to make small transformations to attributes in `~H` templates and validate the required DSL options (like prop variants).

  While this hook empowers you to modify anything in the DSL, it is *strongly* recommended that you excercise restraint, especially in the render functions, as debugging errors caused by transformations will be very opaque to the end user.
  """

  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Pyro.ComponentLibrary.Dsl.Render
  alias Pyro.HEEx
  alias Pyro.HEEx.AST

  @type component :: %Component{} | %LiveComponent{}
  @type context :: map()

  @callback transform_component(component(), map()) :: component()
  @callback config_module() :: module()
  @callback(validate_config(struct()) :: {:ok, struct()}, {:error, String.t()})

  def validate_config(config), do: {:ok, config}

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      import unquote(__MODULE__)

      @impl true
      def config_module, do: __MODULE__.Config

      @impl true
      def validate_config(config), do: {:ok, config}

      defoverridable config_module: 0, validate_config: 1
    end
  end

  @doc """
  Pops matching attributes from all `~H` blocks in a render function. Popped attributes are returned in the context as a nested map:

  ```elixir
  %{
    popped_attributes => %{
      sigil_H_index => %{
        ast_path => popped_attributes
      }
    }
  }
  ```
  """
  @spec pop_render_attrs(Render.t(), HEEx.patterns(), context()) :: {Render.t(), context()}
  def pop_render_attrs(%Render{} = render, patterns, context) do
    transform_heex(
      render,
      fn %AST{} = ast, context ->
        ast = HEEx.pop_attributes(ast, patterns)
        attrs = ast.context.popped_attributes
        context = merge_popped_attributes(context, attrs)
        {ast, context}
      end,
      context
    )
  end

  @spec transform_render_attrs(
          Render.t(),
          HEEx.patterns(),
          transformer :: (list(Attribute.t()), context() -> list(Attribute.t())),
          context()
        ) :: {Render.t(), context()}
  def transform_render_attrs(%Render{} = render, patterns, transformer, context) do
    transform_heex(
      render,
      fn %AST{} = ast, context ->
        ast = HEEx.pop_attributes(ast, patterns)

        ast =
          Enum.reduce(ast.context.popped_attributes, ast, fn {path, attrs}, ast ->
            HEEx.add_attributes!(ast, path, transformer.(attrs, Map.put(context, :ast, ast)))
          end)

        {ast, context}
      end,
      context
    )
  end

  defp merge_popped_attributes(%{popped_attributes: _} = context, attrs) do
    Map.update(
      context,
      context.sigil_H_index,
      attrs,
      &Map.merge(&1, attrs, fn v1, v2 -> v1 ++ v2 end)
    )
  end

  defp merge_popped_attributes(context, attrs) do
    Map.put(context, :popped_attributes, %{context.sigil_H_index => attrs})
  end

  @spec transform_heex(
          Render.t(),
          transformer :: (AST.t(), context() -> {AST.t(), context()}),
          context()
        ) :: {Render.t(), context()}
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

    {%{entity | expr: updated_expr}, context |> Map.delete(:sigil_H_index)}
  end
end
