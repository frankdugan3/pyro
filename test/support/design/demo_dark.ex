defmodule Pyro.Test.Design.DemoDark do
  @moduledoc """
  Fixture that extends `Pyro.Test.Design.Demo` with dark-mode overrides.
  Used to exercise `sources:` merging semantics.
  """

  use Pyro.Design, sources: [Pyro.Test.Design.Demo]

  design do
    group :color do
      # Override Demo's :bg at the same path. Demo's :text stays.
      color :bg, "#0a0a0a"
    end

    # A child-only token that doesn't exist on Demo.
    color :accent_hover, "oklch(0.65 0.25 145)"
  end

  icons do
    # Child adds a new icon — Demo's :chevron_down should still be there.
    icon :moon, ~SVG"""
    <svg viewBox="0 0 24 24"><path d="M21 12a9 9 0 1 1-9-9 7 7 0 0 0 9 9Z"/></svg>
    """
  end
end
