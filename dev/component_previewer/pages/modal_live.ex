defmodule ComponentPreviewer.ModalLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.modal&gt;<:actions>
        <.doc_url page="Phlegethon.Components.Core.html#modal/1" />
      </:actions>
    </.header>

    <%!-- <.modal></.modal> --%>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.modal>")}
  end
end
