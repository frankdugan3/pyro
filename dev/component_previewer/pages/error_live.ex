defmodule ComponentPreviewer.ErrorLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>&lt;.error&gt;<:actions>
    <.doc_url page="Phlegethon.Components.Core.html#error/1" />
    </:actions></.header>

    <.error>Something went wrong!</.error>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.error>")}
  end
end
