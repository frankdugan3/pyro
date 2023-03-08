defmodule ComponentPreviewer.ProgressLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.progress&gt;<:actions>
        <.doc_url page="Phlegethon.Components.Extra.html#progress/1" />
      </:actions>
    </.header>

    <%= for color <- get_prop_value_opts(Phlegethon.Components.Extra, :progress, :overridables, :color) do %>
      <.progress_color_examples color={color} value={assigns[color <> "_value"]} />
    <% end %>
    """
  end

  attr(:color, :string, required: true)
  attr(:value, :integer, required: true)

  def progress_color_examples(assigns) do
    ~H"""
    <section class="grid gap-2 border rounded p-2">
      <h2 class="font-black text-xl bg-root-fg text-root dark:bg-root-fg-dark dark:text-root-dark -mx-2 -mt-2 px-2 pb-1">
        <%= @color %> color
      </h2>
      <.progress_size_examples color={@color} value={@value} />
    </section>
    """
  end

  attr(:color, :string, required: true)
  attr(:value, :integer, required: true)

  def progress_size_examples(assigns) do
    ~H"""
    <%= for size <- get_prop_value_opts(Phlegethon.Components.Extra, :progress, :overridables, :size) do %>
      <.progress value={@value} color={@color} size={size} />
    <% end %>
    """
  end

  @colors get_prop_value_opts(Phlegethon.Components.Extra, :progress, :overridables, :color)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(250, self(), :tick)
    end

    socket =
      @colors
      |> Enum.reduce(socket, fn color, socket ->
        value = Enum.random(10..80)
        assign(socket, color <> "_value", value)
      end)

    {:ok, socket |> assign(:page_title, "<.progress>")}
  end

  @impl true
  def handle_info(:tick, socket) do
    socket =
      @colors
      |> Enum.reduce(socket, fn color, socket ->
        value =
          case socket.assigns[color <> "_value"] + Enum.random(1..10) do
            value when value > 100 -> 0
            value -> value
          end

        assign(socket, color <> "_value", value)
      end)

    {:noreply, socket}
  end
end
