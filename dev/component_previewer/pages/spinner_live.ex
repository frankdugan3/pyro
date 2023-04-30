defmodule ComponentPreviewer.SpinnerLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.spinner&gt;<:actions>
        <.doc_url page="Pyro.Components.Extra.html#spinner/1" />
      </:actions>
    </.header>

    <div>
      <.spinner />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.spinner>")}
  end
end
