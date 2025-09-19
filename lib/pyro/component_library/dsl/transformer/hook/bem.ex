defmodule Pyro.ComponentLibrary.Dsl.Transformer.Hook.BEM do
  @moduledoc """
  A component transformer that applies standard BEM classes.
  """

  @behaviour Pyro.ComponentLibrary.Dsl.Transformer.Hook

  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.LiveComponent

  @impl true
  def transform_component(%LiveComponent{} = live_component, context) do
    live_component
    |> Map.update!(
      :components,
      &Enum.map(&1, fn component ->
        transform_component(component, context)
      end)
    )
  end

  def transform_component(%Component{} = component, _context) do
    component
  end
end
