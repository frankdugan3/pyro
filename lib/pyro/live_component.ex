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
    [
      quote do
        import Phoenix.LiveView
      end,
      quote do
        @behaviour Phoenix.LiveComponent
        @before_compile Phoenix.LiveView.Renderer
      end,
      quote do
        use Pyro.Component, Keyword.take(unquote(opts), [:global_prefixes])

        @doc false
        def __live__, do: %{kind: :component, layout: false}
      end
    ]
  end
end
