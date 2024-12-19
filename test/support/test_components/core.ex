defmodule Pyro.TestComponents.Core do
  @moduledoc false
  use Pyro, library?: true, css_strategy: :tailwind

  component :icon do
    # class :class, ~E|s-4 inline-block| do
    #   strategy :tailwind
    # end

    attr :name, :string, required: true

    template ~H"""
    <span class={[@name, @class]} />
    """
  end

  component :button do
    doc """
    A simple button.
    """

    slot :inner_block, required: true, doc: "the content of the button"

    template ~H"""
    <button><%= render_slot(@inner_block) %></button>
    """
  end
end
