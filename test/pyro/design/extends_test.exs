defmodule Pyro.Design.ExtendsTest do
  use ExUnit.Case, async: true

  alias Pyro.Design.{Info, Token}
  alias Pyro.Test.Design.{Demo, DemoDark}

  describe "DemoDark extends Demo" do
    test "extends_chain/1 is root-to-leaf with the parent" do
      assert Spark.Dsl.Extension.get_persisted(DemoDark, :design_sources_chain) == [Demo]
    end

    test "shared path: child wins at equal paths" do
      # Demo defines :color/:bg as "#ffffff"; DemoDark overrides to "#0a0a0a".
      %Token{value: %Color.SRGB{} = bg} =
        Map.get(Info.tokens(DemoDark), [:color, :bg])

      {r, g, b} = {bg.r, bg.g, bg.b}
      assert_in_delta r, 0x0A / 255, 0.002
      assert_in_delta g, 0x0A / 255, 0.002
      assert_in_delta b, 0x0A / 255, 0.002
    end

    test "parent-only paths are preserved" do
      # Demo defines :color/:text; DemoDark doesn't override.
      assert %Token{type: :color} = Map.get(Info.tokens(DemoDark), [:color, :text])
    end

    test "child-only paths are added" do
      # DemoDark declares :accent_hover at the top level of its design (no group),
      # so the resolved path is just `[:accent_hover]`.
      assert %Token{type: :color} = Map.get(Info.tokens(DemoDark), [:accent_hover])
    end

    test "nested parent-only paths are preserved" do
      # Demo defines :color/:brand/:500; DemoDark doesn't touch it.
      assert %Token{} = Map.get(Info.tokens(DemoDark), [:color, :brand, :"500"])
    end

    test "modifier from parent is preserved" do
      modifiers = Info.modifiers(DemoDark)
      assert Map.has_key?(modifiers, [:color_mode])
    end

    test "icons: parent's icon present, child's icon added" do
      icon_map = Info.icon_map(DemoDark)
      assert Map.has_key?(icon_map, :chevron_down)
      assert Map.has_key?(icon_map, :moon)
    end

    test "parent's :namespace config inherits when child doesn't set it" do
      # DemoDark didn't declare a config block, so namespace inherits from Demo.
      assert Info.namespace(DemoDark) == "demo"
    end
  end
end
