defmodule Pyro.ComponentLibrary.Dsl.Transformer.Hook.BEM do
  @moduledoc """
  A component transformer that applies standard BEM classes.
  """

  @behaviour Pyro.ComponentLibrary.Dsl.Transformer.Hook

  import Pyro.ComponentLibrary.Dsl.Transformer.Hook

  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  # alias Pyro.ComponentLibrary.Dsl.Render

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

  def transform_component(%Component{} = component, context) do
    popped_renders =
      for render <- component.render do
        pop_render_attrs(render, "pyro-*", context)
      end

    for {_, context} <- popped_renders do
      dbg(context.popped_attrs)
    end

    component
    # |> Map.update!(
    #   :render,
    #   &Enum.map(&1, fn %Render{} = render ->
    #
    #   end)
    # )
  end
end
