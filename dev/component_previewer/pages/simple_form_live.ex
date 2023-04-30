defmodule ComponentPreviewer.SimpleFormLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.simple_form&gt;<:actions>
        <.doc_url page="Pyro.Components.Core.html#simple_form/1" />
      </:actions>
    </.header>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.simple_form>")}
  end
end
