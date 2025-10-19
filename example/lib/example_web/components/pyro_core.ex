defmodule ExampleWeb.Components.PyroCore do
  use Pyro,
    component_libraries: Pyro.Components.Core,
    transformer_hook: Pyro.ComponentLibrary.Dsl.Transformer.Hook.DaisyUI
end
