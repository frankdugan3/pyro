defmodule Pyro.Components.Core do
  @moduledoc """
  A core set of functional `.heex` components for building web apps. It is similar to (and often API-compatible with) Phoenix's generated `core_components.ex`.
  """
  use Pyro.ComponentLibrary

  alias Pyro.ComponentLibrary.Dsl.Transformer.Hook.{BEM, DaisyUI}

  @nav_include ~w[href navigate patch method download target rel]
  @daisy_ui_colors ~w[neutral primary secondary accent info success warning error]
  @daisy_ui_default_color "neutral"
  @daisy_ui_sizes ~w[xs sm md lg xl]
  @daisy_ui_default_size "md"

  component :badge do
    doc """
    A badge.
    """

    variant :color, :string, [BEM, DaisyUI] do
      values @daisy_ui_colors
      default @daisy_ui_default_color
    end

    variant :size, :string, [BEM, DaisyUI] do
      values @daisy_ui_sizes
      default @daisy_ui_default_size
    end

    global :rest
    slot :inner_block, required: true

    render assigns do
      ~H"""
      <div pyro-block pyro-variant="color" pyro-variant="size" {@rest}>
        {render_slot(@inner_block)}
      </div>
      """
    end
  end

  component :button do
    doc """
    Renders a button with navigation support.
    """

    block DaisyUI, %DaisyUI.Block{component_class: "btn"}

    variant :color, :string, [BEM, DaisyUI] do
      values @daisy_ui_colors
      default @daisy_ui_default_color
    end

    variant :size, :string, [BEM, DaisyUI] do
      values @daisy_ui_sizes
      default @daisy_ui_default_size
    end

    global :rest, include: @nav_include ++ ~w(value disabled name)
    slot :inner_block, required: true

    render %{rest: rest} = assigns do
      if rest[:href] || rest[:navigate] || rest[:patch] do
        ~H"""
        <.link pyro-block pyro-variant="color" pyro-variant="size" {@rest}>
          {render_slot(@inner_block)}
        </.link>
        """
      else
        ~H"""
        <button pyro-block pyro-variant="color" pyro-variant="size" {@rest}>
          {render_slot(@inner_block)}
        </button>
        """
      end
    end
  end
end
