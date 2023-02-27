defmodule ComponentPreviewer.AlertLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>&lt;.alert&gt;
    <:actions>
    <.doc_url page="Phlegethon.Components.Core.html#alert/1" />
    </:actions></.header>

    <%= for color <- get_prop_value_opts(Phlegethon.Components.Core, :alert, :overridables, :color) do %>
      <.alert_color_examples color={color} />
    <% end %>
    """
  end

  attr(:color, :string, required: true)

  def alert_color_examples(assigns) do
    ~H"""
    <section class="grid gap-2 border rounded p-2">
      <h2 class="font-black text-xl"><%= @color %> color</h2>
      <.alert color={@color}>
        Some content.
      </.alert>
    </section>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.alert>")}
  end
end
