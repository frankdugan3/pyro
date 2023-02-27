defmodule ComponentPreviewer.ProgressLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>&lt;.progress&gt;<:actions>
    <.doc_url page="Phlegethon.Components.Extra.html#progress/1" />
    </:actions></.header>

    <%= for color <- get_prop_value_opts(Phlegethon.Components.Extra, :progress, :overridables, :color) do %>
      <.progress_color_examples color={color} />
    <% end %>
    """
  end

  attr(:color, :string, required: true)

  def progress_color_examples(assigns) do
    ~H"""
    <section class="grid gap-2 border rounded p-2">
      <h2 class="font-black text-xl bg-root-fg text-root dark:bg-root-fg-dark dark:text-root-dark -mx-2 -mt-2 px-2 pb-1">
        <%= @color %> color
      </h2>
      <.progress_size_examples color={@color} />
    </section>
    """
  end

  attr(:color, :string, required: true)

  def progress_size_examples(assigns) do
    ~H"""
    <%= for size <- get_prop_value_opts(Phlegethon.Components.Extra, :progress, :overridables, :size) do %>
      <.progress_value_examples color={@color} size={size} />
    <% end %>
    """
  end

  attr(:color, :string, required: true)
  attr(:size, :string, required: true)

  def progress_value_examples(assigns) do
    ~H"""
    <div class="flex gap-2 justify-start">
      <%= for value <- [25, 50, 75, 100] do %>
        <.progress value={value} color={@color} size={@size} />
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.progress>")}
  end
end
