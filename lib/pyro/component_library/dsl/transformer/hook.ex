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
      sigil_h_index => %{
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
        {ast, attrs} = HEEx.pop_attributes(ast, patterns)
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
        {ast, popped} = HEEx.pop_attributes(ast, patterns)

        ast =
          Enum.reduce(popped, ast, fn {path, attrs}, ast ->
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
      context.sigil_h_index,
      attrs,
      &Map.merge(&1, attrs, fn v1, v2 -> v1 ++ v2 end)
    )
  end

  defp merge_popped_attributes(context, attrs) do
    Map.put(context, :popped_attributes, %{context.sigil_h_index => attrs})
  end

  @spec transform_heex(
          Render.t(),
          transformer :: (AST.t(), context() -> {AST.t(), context()}),
          context()
        ) :: {Render.t(), context()}
  def transform_heex(%Render{sigils: sigils} = render, transformer, context)
      when is_function(transformer, 2) do
    {sigils, context} =
      Enum.reduce(sigils, {sigils, context}, fn {sigil_h_index, ast}, {sigils, context} ->
        context = Map.update(context, :sigil_h_index, 0, &(&1 + 1))
        {ast, context} = transformer.(ast, context)
        {Map.put(sigils, sigil_h_index, ast), context}
      end)

    {%{render | sigils: sigils}, context |> Map.delete(:sigil_h_index)}
  end
end
