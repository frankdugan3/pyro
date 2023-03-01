defmodule ComponentPreviewer.ButtonLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.button&gt;<:actions>
        <.doc_url page="Phlegethon.Components.Core.html#button/1" />
      </:actions>
    </.header>

    <p>
      Buttons also support links via <var>href</var>, <var>navigate</var>
      or <var>patch</var>! In those cases, it basically wraps the default Phoenix <var>.link</var>
      component with button style.
    </p>

    <p>
      Otherwise, it renders an HTML <var>button</var> with some added niceties.
    </p>

    <%= for color <- get_prop_value_opts(Phlegethon.Components.Core, :button, :overridables, :color) do %>
      <.button_color_examples color={color} />
    <% end %>
    """
  end

  attr(:color, :string, required: true)

  def button_color_examples(assigns) do
    ~H"""
    <section class="grid gap-2 border rounded p-2">
      <h2 class="font-black text-xl bg-root-fg text-root dark:bg-root-fg-dark dark:text-root-dark -mx-2 -mt-2 px-2 pb-1">
        <%= @color %> color
      </h2>
      <.button_size_examples color={@color} />
      <.button_size_examples color={@color} opts={[pill: true]} />
      <.button_size_examples color={@color} opts={[outline: true]} />
      <.button_size_examples color={@color} opts={[outline: true, pill: true]} />
    </section>
    """
  end

  attr(:color, :string, required: true)
  attr(:opts, :list, default: [])

  def button_size_examples(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2 justify-start items-end">
      <%= for size <- get_prop_value_opts(Phlegethon.Components.Core, :button, :overridables, :size) do %>
        <.button color={@color} size={size} {@opts}>
          <%= [size | Keyword.keys(@opts)] |> Enum.join(" · ") %>
        </.button>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.button>")}
  end
end
