defmodule ComponentPreviewer.HeaderLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>&lt;.header&gt;<:actions>
    <.doc_url page="Phlegethon.Components.Core.html#header/1" />
    </:actions></.header>

    <.header>
      Amazing Thing
      <:subtitle>It's almost as good as sliced bread.</:subtitle>
      <:actions>
        <.button>An Action</.button>
        <.button>Another</.button>
      </:actions>
    </.header>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.header>")}
  end
end
