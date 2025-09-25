defmodule Pyro.ComponentLibrary.Dsl.Transformer.Hook.BEM do
  @moduledoc """
  A component transformer that applies standard BEM classes.
  """

  @behaviour Pyro.ComponentLibrary.Dsl.Transformer.Hook

  import Pyro.ComponentLibrary.Dsl.Transformer.Hook

  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Pyro.ComponentLibrary.Dsl.Render

  @impl true
  def transform_component(%LiveComponent{} = live_component, context) do
    live_component
    |> do_transform(context)
    |> Map.update!(
      :components,
      &Enum.map(&1, fn component ->
        transform_component(component, context)
      end)
    )
  end

  def transform_component(%Component{} = component, context) do
    do_transform(component, context)
  end

  defp do_transform(component, context) do
    component
    |> Map.update!(:render, fn renders ->
      for %Render{} = render <- renders do
        {render, context} = pop_render_attrs(render, [~r"^pyro-", "class"], context)
        context.popped_attributes |> dbg()
        render
      end
    end)
  end
end
