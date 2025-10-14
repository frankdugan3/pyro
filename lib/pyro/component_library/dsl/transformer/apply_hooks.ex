defmodule Pyro.ComponentLibrary.Dsl.Transformer.ApplyHooks do
  @moduledoc false
  use Spark.Dsl.Transformer

  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.HookConfig
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Pyro.ComponentLibrary.Dsl.Render
  alias Pyro.ComponentLibrary.Dsl.Transformer.MergeComponents
  alias Pyro.HEEx.AST
  alias Spark.Dsl.Entity
  alias Spark.Dsl.Transformer
  alias Spark.Error.DslError

  @impl true
  def after?(module), do: module in [MergeComponents]

  @impl true
  def transform(dsl) do
    if Transformer.get_persisted(dsl, :component_library?, false) do
      {:ok, dsl}
    else
      hook =
        Transformer.get_persisted(dsl, :transformer_hook)

      config =
        dsl
        |> get_config(hook)
        |> validate_config(dsl, hook)

      context = %{
        config: config,
        dsl: dsl,
        module: Transformer.get_persisted(dsl, :module),
        path: [:components]
      }

      components =
        for %module{} = component when module in [Component, LiveComponent] <-
              Transformer.get_entities(dsl, [:components]) do
          component
          |> hook.transform_component(context)
          |> Map.update!(:render, &apply_ast/1)
        end

      dsl =
        Transformer.remove_entity(dsl, [:components], fn
          %Component{} -> true
          %LiveComponent{} -> true
          _ -> false
        end)

      dsl = Enum.reduce(components, dsl, &Transformer.add_entity(&2, [:components], &1))

      {:ok, dsl}
    end
  end

  defp apply_ast(renders) when is_list(renders) do
    Enum.map(renders, &apply_ast/1)
  end

  defp apply_ast(%Render{} = render) do
    expr =
      Macro.prewalk(render.expr, 0, fn
        {:sigil_H, meta, [{:<<>>, string_meta, [content]}, modifiers]}, index ->
          content =
            case Map.get(render.sigils, index) do
              %AST{} = ast -> AST.encode(ast)
              _ -> content
            end

          {{:sigil_H, meta, [{:<<>>, string_meta, [content]}, modifiers]}, index + 1}

        node, acc ->
          {node, acc}
      end)

    %{render | expr: expr}
  end

  def get_config(dsl, hook) do
    case dsl
         |> Transformer.get_entities([:hooks])
         |> Enum.find(fn
           %HookConfig{hook: ^hook} ->
             true

           _ ->
             nil
         end) do
      nil -> %HookConfig{opts: struct(hook.config_module())}
      config -> config
    end
  end

  def validate_config(%{opts: opts} = hook_config, dsl, hook) when not is_struct(opts) do
    raise DslError,
      module: Transformer.get_persisted(dsl, :module),
      path: [:hooks],
      location: Entity.anno(hook_config),
      message: """
      Hook config for #{hook} must be a #{hook.config_module()} struct
      """
  end

  def validate_config(hook_config, dsl, hook) do
    case hook.validate_config(hook_config.opts) do
      {:ok, config} ->
        config

      {:error, message} ->
        raise DslError,
          module: Transformer.get_persisted(dsl, :module),
          path: [:hooks],
          location: Entity.anno(hook_config),
          message: message
    end
  end
end
