defmodule TestButton do
  @moduledoc false
  use Pyro,
    transformer_hook: Pyro.ComponentLibrary.Dsl.Transformer.Hook.BEM,
    css_output_path: "tmp/test_components",
    component_output_path: "tmp/test_components"

  component :button do
    prop :normal, :boolean, default: true

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
