defmodule ComponentPreviewer.Hooks.Page do
  @moduledoc false
  import Phoenix.Component, only: [assign: 3]

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> Phoenix.LiveView.attach_hook(:uri_hook, :handle_params, fn _params, uri, socket ->
       {:cont, assign(socket, :uri, uri)}
     end)}
  end
end
