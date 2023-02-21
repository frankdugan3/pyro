defmodule ComponentPreviewer.Layouts do
  @moduledoc false
  use ComponentPreviewer, :html

  embed_templates("layouts/*")

  attr(:uri, :string, required: true)
  attr(:current_uri, :string, required: true)
  attr(:label, :string, required: true)

  def nav_link(assigns) do
    ~H"""
    <.link class={link_class(@current_uri, @uri)} navigate={@uri}>
      <%= @label %>
    </.link>
    """
  end

  def link_class(current_uri, uri) do
    %{path: current_path} = URI.parse(current_uri)
    %{path: path} = URI.parse(uri)

    color =
      if current_path == path do
        "text-brand-2"
      else
        "text-root-fg dark:text-root-fg-dark"
      end

    color <> " font-black hover:text-brand-3 dark:hover:text-brand-3 text-xl select-none"
  end
end
