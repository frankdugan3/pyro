defmodule ComponentPreviewer.SlideOverLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.slide_over&gt;<:actions>
        <.doc_url page="Pyro.Components.Extra.html#slide_over/1" />
      </:actions>
    </.header>

    <div class="flex gap-2">
      <.button :for={origin <- ~w[left top right bottom]} patch={~p"/slide-over/#{origin}"}>
        Open Slide Over from <%= origin %>
      </.button>
    </div>

    <%= if @slide_over do %>
      <.slide_over origin={@slide_over} max_width="sm" title="Slide Over">
        <p>
          This is a slide over.
        </p>
      </.slide_over>
    <% end %>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "<.slide_over>")
     |> assign(:slide_over, false)}
  end

  def handle_params(params, _, socket) do
    case socket.assigns.live_action do
      :slide_over ->
        {:noreply,
         socket
         |> assign(:slide_over, params["origin"])}

      _ ->
        {:noreply,
         socket
         |> assign(:slide_over, false)}
    end
  end

  def handle_event("close_slide_over", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/slide-over")}
  end
end
