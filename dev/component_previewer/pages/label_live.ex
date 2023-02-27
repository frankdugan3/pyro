defmodule ComponentPreviewer.LabelLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>&lt;.label&gt;<:actions>
    <.doc_url page="Phlegethon.Components.Core.html#label/1" />
    </:actions></.header>

    <.label>Something</.label>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.label>")}
  end
end
