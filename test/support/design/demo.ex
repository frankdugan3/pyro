defmodule Pyro.Test.Design.Demo do
  @moduledoc "End-to-end DTCG Design fixture used by DSL tests."

  use Pyro.Design

  design do
    group :color do
      color :bg, "#ffffff"
      color :text, "oklch(0.15 0.02 250)"

      group :brand do
        type :color
        description "Brand palette."

        color(:"50", "oklch(0.97 0.02 250)")
        color(:"500", "oklch(0.55 0.18 250)")
        color(:"900", "oklch(0.15 0.08 250)")
      end

      group :accent do
        root(:color, "oklch(0.7 0.25 145)")
        color(:hover, "oklch(0.65 0.25 145)")
      end

      group :button do
        extends("#/color/brand")

        color(:pressed, "oklch(0.45 0.2 250)")
      end
    end

    group :space do
      type :dimension

      dimension :xs, 0.25, :rem
      dimension :md, 1.0, :rem
      dimension :squish_block, 0.5, :rem
    end

    group :motion do
      group :duration do
        type :duration

        duration(:fast, 150, :ms)
      end

      group :easing do
        type :cubic_bezier

        cubic_bezier(:standard, {0.2, 0.0, 0.0, 1.0})
      end
    end

    shadow :card do
      color("#0003")
      offset_x({0, :px})
      offset_y({1, :px})
      blur({2, :px})
      spread({0, :px})
    end

    typography :display do
      font_family ["Inter Display", "Inter"]
      font_size({3.0, :rem})
      font_weight(800)
      line_height(1.05)
    end

    ref :primary_action, "#/color/brand/500"

    modifier :color_mode do
      description "Light vs dark mode."
      default :light

      context :light do
        color :bg, "#ffffff"
        color :text, "oklch(0.15 0.02 250)"
      end

      context :dark do
        color :bg, "#0a0a0a"
        color :text, "oklch(0.95 0.01 250)"
      end
    end
  end

  icons do
    icon :chevron_down, ~SVG"""
    <svg viewBox="0 0 24 24"><path d="M6 9l6 6 6-6"/></svg>
    """
  end

  config do
    namespace "demo"
  end
end
