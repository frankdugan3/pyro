defmodule ComponentPreviewer.ListLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>&lt;.list&gt;</.header>

    <.list>
      <:item title="Something">a thing</:item>
      <:item title="Nothing">the absence of any thing</:item>
    </.list>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.list>")}
  end
end
