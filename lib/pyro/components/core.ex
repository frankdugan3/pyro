defmodule Pyro.Components.Core do
  @moduledoc """
  A core set of functional `.heex` components for building web apps. It is similar to (and often API-compatible with) Phoenix's generated `core_components.ex`.

  Compared to Phoenix's generated components, Pyro's implementation adds:

  - Maintenance/bugfixes/new features, since it's a library
  - A powerful DSL for customization
  - Inputs
    - `autofocus` prop for reliable focus on mount
    - `hidden` input type with a slot for custom content
  - A rich flash experience
    - Auto-remove after (configurable) timeout
    - Progress bar for auto-removed flash messages
    - Define which flashes are included in which trays (supports multiple trays)
  - Slightly cleaner, more semantic markup
  - Extra components

  There are more complex components outside the `Core` module, be sure to check those out as well.
  """
  use Pyro.ComponentLibrary

  alias Pyro.ComponentLibrary.Dsl.Transformer.Hook.{BEM, DaisyUI}

  @nav_include ~w(href navigate patch method download target rel)

  component :button do
    doc """
    Renders a button with navigation support.

    ## Examples

        <.button>Send!</.button>
        <.button phx-click="go" color="primary" size="lg">Send!</.button>
        <.button navigate={~p"/"}>Home</.button>
    """

    block DaisyUI do
      meta %{base_class: "btn"}
    end

    variant :color, :string, [BEM, DaisyUI] do
      values ~w[neutral primary secondary accent info success warning error]
      default "neutral"
    end

    variant :size, :string, [BEM, DaisyUI] do
      values ~w[xs sm md lg xl]
      default "md"
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
