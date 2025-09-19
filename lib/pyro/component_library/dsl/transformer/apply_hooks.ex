defmodule Pyro.ComponentLibrary.Dsl.Transformer.ApplyHooks do
  @moduledoc false
  use Spark.Dsl.Transformer

  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Pyro.ComponentLibrary.Dsl.Transformer.MergeComponents
  alias Spark.Dsl.Transformer

  @impl true
  def after?(module), do: module in [MergeComponents]

  @impl true
  def transform(dsl) do
    if Transformer.get_persisted(dsl, :component_library?, false) do
      {:ok, dsl}
    else
      hook =
        Transformer.get_persisted(dsl, :transformer_hook)

      context = %{
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
end
