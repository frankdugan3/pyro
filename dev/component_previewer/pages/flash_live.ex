defmodule ComponentPreviewer.FlashLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>&lt;.flash&gt;</.header>

    <p>You should see flash messages on page mount.</p>

    <.flash_group
      class="static"
      flash={@flash}
      flash_class="z-auto"
      include_kinds={~w[permanent dismissible auto-close]}
    />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      Phlegethon.Components.Core
      |> get_prop_value_opts(:flash, :overridables, :kind)
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
            - Should have the "success" style, but with a different icon
          """,
          ttl: 0,
          title: "A Different Kind of Flash",
          icon_name: "light_bulb",
          style_for_kind: "success",
          close: false
        )
      )
      |> put_flash(
        "dismissible",
        encode_flash(
          "This is a flash to test default style. It also doesn't auto-close. And has a custom title and icon.",
          title: "TOTALLY CUSTOM",
          ttl: 0,
          icon_name: "beaker"
        )
      )
      |> put_flash(
        "auto-close",
        "This is a simple one that only shows in the page flash tray."
      )

    {:ok, socket |> assign(:page_title, "<.flash>")}
  end
end
