defmodule Phlegethon.LiveView do
  @moduledoc ~S'''
  This is basically a wrapper around `Phoenix.LiveView`, but it uses `Phlegethon.Component` instead of `Phoenix.Component` to enable Phlegethon's extended features.

  ```
  use Phlegethon.LiveView
  ```

  > #### Note: {: .info}
  >
  > Please see the `Phoenix.LiveView` docs, as they will not be duplicated here.
  '''

  @doc false
  defmacro __using__(opts) do
    opts =
      with true <- Keyword.keyword?(opts),
           {layout, template} <- Keyword.get(opts, :layout) do
        layout = Macro.expand(layout, %{__CALLER__ | function: {:__live__, 0}})
        Keyword.replace!(opts, :layout, {layout, template})
      else
        _ -> opts
      end

    quote bind_quoted: [opts: opts] do
      import Phoenix.LiveView
      @behaviour Phoenix.LiveView
      @before_compile Phoenix.LiveView.Renderer

      @phoenix_live_opts opts
      Module.register_attribute(__MODULE__, :phoenix_live_mount, accumulate: true)
      @before_compile Phoenix.LiveView

      use Phlegethon.Component, opts
    end
  end
end
