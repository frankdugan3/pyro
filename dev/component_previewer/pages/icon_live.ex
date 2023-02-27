defmodule ComponentPreviewer.IconLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>&lt;.icon&gt;<:actions>
    <.doc_url page="Phlegethon.Components.Icon.html#icon/1" />
    </:actions></.header>

    <.icon name={:arrow_left} />
    <.icon name={:arrow_right} kind={:mini} class="block" />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.icon>")}
  end
end
