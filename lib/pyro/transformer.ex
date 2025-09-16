defmodule Pyro.Transformer do
  @moduledoc """
  Shared tooling for transforming Pyro DSL.
  """
  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Spark.Dsl.Transformer

  @doc """
  Scaffold a Pyro DSL transformer, importing standard tooling.
  """
  @doc type: :macro
  defmacro __using__(_env) do
    quote do
      use Spark.Dsl.Transformer

      import unquote(__MODULE__)

      alias Spark.Dsl.Transformer
      alias Spark.Error.DslError
    end
  end

  @doc """
  Updates the DSL by removing all existing function components, and adding the new list of function components.
  """
  @spec replace_components(map(), [Component.t()]) ::
          map()
  def replace_components(dsl_state, components) do
    dsl_state =
      dsl_state
      |> Pyro.Info.components()
      |> Enum.reduce(dsl_state, fn component, dsl_state ->
        Transformer.remove_entity(
          dsl_state,
          [:components],
          &(&1.__struct__ == component.__struct__ && &1.name == component.name)
        )
      end)

    Enum.reduce(
      components,
      dsl_state,
      &Transformer.add_entity(&2, [:components], &1)
    )
  end

  @doc """
  Updates the DSL by removing all existing live components, and adding the new list of live components.
  """
  @spec replace_live_components(map(), [LiveComponent.t()]) ::
          map()
  def replace_live_components(dsl_state, live_components) do
    dsl_state =
      dsl_state
      |> Pyro.Info.live_components()
      |> Enum.reduce(dsl_state, fn live_component, dsl_state ->
        Transformer.remove_entity(
          dsl_state,
          [:components],
          &(&1.__struct__ == live_component.__struct__ && &1.module == live_component.module)
        )
      end)

    Enum.reduce(
      live_components,
      dsl_state,
      &Transformer.add_entity(&2, [:components], &1)
    )
  end
end
