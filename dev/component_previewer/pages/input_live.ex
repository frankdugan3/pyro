defmodule ComponentPreviewer.InputLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.input&gt;<:actions>
        <.doc_url page="Pyro.Components.Core.html#input/1" />
      </:actions>
    </.header>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.input>")}
  end
end
