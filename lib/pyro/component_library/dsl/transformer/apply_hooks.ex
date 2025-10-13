defmodule Pyro.ComponentLibrary.Dsl.Transformer.ApplyHooks do
  @moduledoc false
  use Spark.Dsl.Transformer

  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.HookConfig
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Pyro.ComponentLibrary.Dsl.Transformer.MergeComponents
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
          hook.transform_component(component, context)
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
