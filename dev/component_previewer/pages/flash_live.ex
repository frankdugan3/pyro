defmodule ComponentPreviewer.FlashLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.flash&gt;<:actions>
        <.doc_url page="Phlegethon.Components.Core.html#flash/1" />
      </:actions>
    </.header>

    <p>You should see flash messages on page mount.</p>

    <.flash_group
      class="static"
      flash={@flash}
      include_kinds={~w[permanent dismissible auto-close]}
    />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      Phlegethon.Overrides.override_for({Phlegethon.Components.Core, :flash}, :kinds)
      |> Enum.reduce(socket, fn kind, socket ->
        put_flash(
          socket,
          kind,
          encode_flash(~s[This is a flash of kind "#{kind}"], ttl: Enum.random(5..15) * 1_000)
        )
      end)
      |> put_flash(
        "permanent",
        encode_flash(
          """
          This flash message:
            - Should *not* show up in app's floating flash tray
            - Should show up on the page's flash tray
            - Should not be dismissible
            - Should have the "brand" style, but with an icon and title
          """,
          ttl: 0,
          title: "A Different Kind of Flash",
          icon_name: "hero-light-bulb-mini",
          style_for_kind: "brand",
          close: false
        )
      )
      |> put_flash(
        "dismissible",
        encode_flash(
          "This is a flash to test default style. It also doesn't auto-close. And has a custom title and icon.",
          title: "TOTALLY CUSTOM",
          ttl: 0,
          icon_name: "hero-beaker-mini"
        )
      )
      |> put_flash(
        "auto-close",
        "This is a simple one that only shows in the page flash tray."
      )

    {:ok, socket |> assign(:page_title, "<.flash>")}
  end
end
