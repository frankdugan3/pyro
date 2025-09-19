defmodule Pyro.ComponentLibrary.Dsl.Transformer.Hook.TailwindComponents do
  @moduledoc """
  A component transformer that merges component classes intended to be compatible with Tailwind's layers, theme and utilities.
  """

  @behaviour Pyro.ComponentLibrary.Dsl.Transformer.Hook

  @impl true
  def transform_component(component, _context) do
    component
  end
end
