##############################################################################
####    O R I G I N A L    L I C E N S E
##############################################################################

# Copyright (c) 2018 Chris McCord

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

##############################################################################
####    M O D I F I C A T I O N    N O T I C E
##############################################################################

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
