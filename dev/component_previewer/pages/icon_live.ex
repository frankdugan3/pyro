defmodule ComponentPreviewer.IconLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.icon&gt;<:actions>
        <.doc_url page="Phlegethon.Components.Icon.html#icon/1" />
      </:actions>
    </.header>

    <%= for kind <- get_prop_value_opts(Phlegethon.Components.Icon, :icon, :overridables, :kind) do %>
      <.icon_kind_examples kind={kind} />
    <% end %>
    """
  end

  attr(:kind, :string, required: true)

  def icon_kind_examples(assigns) do
    ~H"""
    <section class="grid gap-2 border rounded p-2">
      <h2 class="font-black text-xl bg-root-fg text-root dark:bg-root-fg-dark dark:text-root-dark -mx-2 -mt-2 px-2 pb-1">
        <%= @kind %>
      </h2>
      <.icon_name_examples kind={@kind} />
    </section>
    """
  end

  attr(:kind, :string, required: true)
  attr(:opts, :list, default: [])

  def icon_name_examples(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2 justify-start items-end">
      <%= for name <- get_prop_value_opts(Phlegethon.Components.Icon, :icon, :attrs, :name) |> Enum.sort() do %>
        <.tooltip
          id={"#{name}-#{@kind}-tooltip"}
          icon_name={name}
          icon_class="h-6 w-6"
          tooltip={inspect(name)}
          icon_kind={@kind}
        />
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.icon>")}
  end
end
