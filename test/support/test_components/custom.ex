defmodule Pyro.TestComponents.Custom do
  @moduledoc false
  use Pyro,
    component_libraries: [Pyro.TestComponents.Core],
    transformer_hook: Pyro.ComponentLibrary.Dsl.Transformer.Hook.BEM,
    css_output_path: "tmp/test_components",
    component_output_path: "tmp/test_components"
end
