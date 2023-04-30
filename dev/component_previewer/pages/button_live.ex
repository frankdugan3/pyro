defmodule ComponentPreviewer.ButtonLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.button&gt;<:actions>
        <.doc_url page="Pyro.Components.Core.html#button/1" />
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

    <ul class="flex flex-wrap gap-2">
      <%= for color <- Pyro.Overrides.override_for(Pyro.Components.Core, :button, :colors) do %>
        <li>
          <.a href={"#color-#{color}"}><%= color %></.a>
        </li>
      <% end %>
    </ul>

    <%= for color <- Pyro.Overrides.override_for(Pyro.Components.Core, :button, :colors) do %>
      <.button_color_examples color={color} />
    <% end %>
    """
  end

  attr(:color, :string, required: true)

  def button_color_examples(assigns) do
    ~H"""
    <section class="grid gap-2 border rounded p-2">
      <h2
        id={"color-" <> @color}
        class="font-black text-xl bg-root-fg text-root dark:bg-root-fg-dark dark:text-root-dark -mx-2 -mt-2 px-2 pb-1"
      >
        COLOR: <%= @color %> ||
        <.a
          :for={
            color <-
              Pyro.Overrides.override_for(Pyro.Components.Core, :button, :colors)
              |> Enum.filter(&(&1 != @color))
          }
          href={"#color-#{color}"}
          class="text-primary-200 dark:text-primary-400"
        >
          <%= color %>
        </.a>
      </h2>
      <%= for shape <- Pyro.Overrides.override_for(Pyro.Components.Core, :button, :shapes)do %>
        <h3 class="w-full font-black text-lg px-2 pb-1 border-b-2">
          SHAPE: <%= shape %>
        </h3>
        <%= for variant <- Pyro.Overrides.override_for(Pyro.Components.Core, :button, :variants) do %>
          <.button_size_examples color={@color} variant={variant} shape={shape} />
          <.button_size_examples
            color={@color}
            variant={variant}
            shape={shape}
            opts={[loading: true]}
          />
          <.button_size_examples color={@color} variant={variant} shape={shape} opts={[ping: true]} />
          <.button_size_examples
            color={@color}
            variant={variant}
            shape={shape}
            opts={[disabled: true]}
          />
          <.button_size_examples
            color={@color}
            variant={variant}
            shape={shape}
            icon_name="hero-cpu-chip-solid"
          />
        <% end %>
      <% end %>
    </section>
    """
  end

  attr :color, :string, required: true
  attr :shape, :string, required: true
  attr :variant, :string, required: true
  attr :icon_name, :string, default: nil
  attr :opts, :list, default: []

  def button_size_examples(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2 justify-start items-end">
      <%= for size <- Pyro.Overrides.override_for(Pyro.Components.Core, :button, :sizes) do %>
        <.button
          color={@color}
          size={size}
          shape={@shape}
          icon_name={@icon_name}
          variant={@variant}
          {@opts}
        >
          <%= [size | [@variant | Keyword.keys(@opts)]] |> Enum.join(" · ") %>
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
