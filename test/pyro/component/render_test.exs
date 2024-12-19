defmodule Pyro.Component.RenderTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Pyro.TestComponents.Custom

  import Phoenix.LiveViewTest

  alias Pyro.TestComponents.Custom

  test "components are configured" do
    assert render_component(&simple/1,
             text: "render me daddy"
           ) == ~S|<div>render me daddy</div>|
  end

  test "default options are propagated from libraries" do
    assert :tailwind = Pyro.Info.css_strategy(Custom)
  end
end
