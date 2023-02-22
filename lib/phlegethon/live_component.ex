# Original file: phoenix_live_component.ex from Phoenix LiveView (https://github.com/phoenixframework/phoenix_live_view/blob/master/lib/phoenix_live_component.ex)
# Modifications: Change references to Phoenix.LiveComponent and Phoenix.LiveView for compatibility reasons.
# Copyright 2023 Frank Dugan III
# Licensed under the MIT license

defmodule Phlegethon.LiveComponent do
  @moduledoc ~S'''
  This is basically the same thing as `Phoenix.LiveComponent`, but imports `Phlegethon.LiveView` and `Phlegethon.Component` instead of `Phoenix.LiveView` and `Phoenix.Component` for proper validation of Phlegethon's extended features. Otherwise, there would be false warnings about undefined attributes, etc.

  ```
  use Phlegethon.LiveComponent
  ```

  > #### Note: {: .info}
  >
  > Please see the `Phoenix.LiveComponent` docs, as they will not be duplicated here.
  '''

  alias Phoenix.LiveView.Socket

  @doc false
  defmacro __using__(opts \\ []) do
    quote do
      import Phlegethon.LiveView
      @behaviour Phlegethon.LiveComponent
      @before_compile Phoenix.LiveView.Renderer

      # Phlegethon.Component must come last so its @before_compile runs last
      use Phlegethon.Component, Keyword.take(unquote(opts), [:global_prefixes])

      @doc false
      def __live__, do: %{kind: :component, module: __MODULE__, layout: false}
    end
  end

  @callback mount(socket :: Socket.t()) ::
              {:ok, Socket.t()} | {:ok, Socket.t(), keyword()}

  @callback preload(list_of_assigns :: [Socket.assigns()]) ::
              list_of_assigns :: [Socket.assigns()]

  @callback update(assigns :: Socket.assigns(), socket :: Socket.t()) ::
              {:ok, Socket.t()}

  @callback render(assigns :: Socket.assigns()) :: Phoenix.LiveView.Rendered.t()

  @callback handle_event(
              event :: binary,
              unsigned_params :: Phlegethon.LiveView.unsigned_params(),
              socket :: Socket.t()
            ) ::
              {:noreply, Socket.t()} | {:reply, map, Socket.t()}

  @optional_callbacks mount: 1, preload: 1, update: 2, handle_event: 3
end
