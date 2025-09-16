defmodule Pyro.TestComponents.Core do
  @moduledoc false
  use Pyro.ComponentLibrary

  component :button do
    global :rest, include: ~w(href navigate patch method)
    prop :normal, :boolean, default: true
    calc :sum, fn assigns -> assigns[:a] + assigns[:b] end
    slot :inner_block, required: true, doc: "the content of the button"

    render %{rest: rest} = assigns do
      if rest[:href] || rest[:navigate] || rest[:patch] do
        ~H"""
        <script :type={ColocatedHook} name=".ButtonManager">
          {mounted() {}}
        </script>
        <.link pyro-component pyro-variant="color" pyro-variant="size" phx-hook=".ButtonManager" {@rest}>
          {render_slot(@inner_block)}
        </.link>
        """
      else
        ~H"""
        <button pyro-component pyro-variant="color" pyro-variant="size" {@rest}>
          {render_slot(@inner_block)}
        </button>
        """
      end
    end
  end
end
