defmodule Pyro.Component.CoreTest do
  @moduledoc false

  alias Pyro.ComponentLibrary.Dsl.Transformer.Hook.{BEM, DaisyUI}
  alias Pyro.Components.Core

  defmodule CoreBEM do
    use Pyro,
      # debug?: true,
      component_libraries: Core,
      transformer_hook: BEM

    css do
      prefix "pyro-"
    end
  end

  defmodule CoreDaisyUI do
    use Pyro,
      debug?: true,
      component_libraries: Core,
      transformer_hook: DaisyUI

    hook DaisyUI, %DaisyUI.Config{prefix: "d-", tailwind_prefix: "tw"}
  end
end
