defmodule Phlegethon.Components.Extra do
  use Phlegethon.Component

  @moduledoc """
  Original components provided by Phlegethon.
  """

  # import Phlegethon.Component.Core, only: [flash: 1]

  @doc """
  Renders a code block.
  """
  @doc type: :component

  overridable :class, :class,
    required: true,
    doc: "Merge/override default classes of the `code` element"

  attr :source, :string, required: true, doc: "The code snippet"

  attr :language, :string,
    default: "elixir",
    values: ~w[elixir heex html none],
    doc: "Language of the code snippet"

  def code(assigns) do
    ~H"""
    <code class={@class} phx-no-format><%= format_code(@source, @language) %></code>
    """
  end

  defp format_code(source, language) do
    case language do
      "none" -> source
      lexer -> Makeup.highlight_inner_html(source, lexer: lexer)
    end
    |> Phoenix.HTML.raw()
  end

  @doc """
  A progress element. Styling the progress element is tricky, so this wraps it with some nice conveniences.
  """
  @doc type: :component

  overridable :class, :class, required: true, doc: "The class of the progress bar"

  overridable :size, :string,
    required: true,
    values: :sizes,
    doc: "The size of the progress bar"

  overridable :color, :string,
    required: true,
    values: :colors,
    doc: "The color of the progress bar"

  attr :max, :integer, default: 100
  attr :value, :integer, default: 0
  attr :rest, :global

  def progress(assigns) do
    ~H"""
    <progress value={@value} max={@max} class={@class} {@rest} />
    """
  end
end
