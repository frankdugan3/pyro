defmodule ComponentPreviewer.ALive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.a&gt;<:actions>
        <.doc_url page="Pyro.Components.Extra.html#a/1" />
      </:actions>
    </.header>

    <p>
      <.a navigate={~p"/"}>A link back home.</.a>
    </p>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.a>")}
  end
end
