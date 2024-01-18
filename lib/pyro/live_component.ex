defmodule Pyro.LiveComponent do
  @moduledoc ~S'''
  This is basically a wrapper around `Phoenix.LiveComponent`, but it uses `Pyro.Component` instead of `Phoenix.Component` to enable Pyro's extended features.

  ```
  use Pyro.LiveComponent
  ```

  > #### Note: {: .info}
  >
  > Please see the `Phoenix.LiveComponent` docs, as they will not be duplicated here.
  '''

  @doc false
  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      import Phoenix.LiveView
      @behaviour Phoenix.LiveComponent
      @before_compile Phoenix.LiveView.Renderer

      # Pyro.Component must come last so its @before_compile runs last
      use Pyro.Component, opts

      @doc false
      def __live__, do: %{kind: :component, module: __MODULE__, layout: false}
    end
  end
end
