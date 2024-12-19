defmodule Pyro.Transformer.ApplyDefaults do
  @moduledoc """
  Apply all the default values to DSL.

  > #### Note: {: .warning}
  >
  > We can't leverage the built-in option defaults because we are *merging* entities and therefore need to keep track of which fields have been assigned.
  """

  use Pyro.Transformer

  @doc false
  @impl true
  def after?(module) do
    module in [Pyro.Transformer.ApplyVariables]
  end

  @doc false
  @impl true
  def transform(dsl_state) do
    if Spark.Dsl.Extension.get_persisted(dsl_state, :library?) do
      {:ok, dsl_state}
    else
      scope = %{normalizer: Pyro.Info.css_normalizer(dsl_state)}

      components =
        dsl_state
        |> Pyro.Info.components()
        |> Enum.map(&apply_component_defaults(&1, scope))

      live_components =
        dsl_state
        |> Pyro.Info.live_components()
        |> Enum.map(&apply_live_component_defaults(&1, scope))

      dsl_state =
        dsl_state
        |> replace_components(components)
        |> replace_live_components(live_components)

      {:ok, dsl_state}
    end
  end

  defp apply_live_component_defaults(%Pyro.Schema.LiveComponent{} = live_component, scope) do
    live_component
    |> maybe_default(:private?, false)
    |> Map.update!(:classes, fn classes ->
      Enum.map(classes, &apply_class_defaults(&1, scope))
    end)
    |> Map.update!(:attrs, fn attrs ->
      Enum.map(attrs, &apply_attr_defaults(&1, scope))
    end)
    |> Map.update!(:slots, fn slots ->
      Enum.map(slots, &apply_slot_defaults(&1, scope))
    end)
    |> Map.update!(:components, fn components ->
      Enum.map(components, &apply_component_defaults(&1, scope))
    end)
  end

  defp apply_component_defaults(%Pyro.Schema.Component{} = component, scope) do
    component
    |> maybe_default(:private?, false)
    |> Map.update!(:attrs, fn attrs ->
      Enum.map(attrs, &apply_attr_defaults(&1, scope))
    end)
    |> Map.update!(:slots, fn slots ->
      Enum.map(slots, &apply_slot_defaults(&1, scope))
    end)
  end

  defp apply_attr_defaults(%Pyro.Schema.Attr{} = attr, _scope) do
    attr
    |> maybe_default(:type, :any)
    |> maybe_default(:required, false)
  end

  defp apply_slot_defaults(%Pyro.Schema.Slot{} = slot, scope) do
    slot
    |> maybe_default(:required, false)
    |> maybe_default(:validate_attrs, true)
    |> Map.update!(:attrs, fn attrs ->
      Enum.map(attrs, &apply_attr_defaults(&1, scope))
    end)
  end

  defp maybe_default(entity, key, default) do
    Map.update!(entity, key, &maybe_default(&1, default))
  end

  defp maybe_default(value, default) when is_nil(value), do: default
  defp maybe_default(value, _default), do: value
end
