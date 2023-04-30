defmodule ComponentPreviewer.CopyToClipboardLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.copy_to_clipboard&gt;<:actions>
        <.doc_url page="Pyro.Components.Extra.html#copy_to_clipboard/1" />
      </:actions>
    </.header>

    <p>
      <.copy_to_clipboard id="simple-copy" value="#COPYALLTHETHINGS" />
    </p>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.copy_to_clipboard>")}
  end
end
