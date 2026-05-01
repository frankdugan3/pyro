defmodule Pyro.Design.DslTest do
  use ExUnit.Case, async: true

  alias Pyro.Design.{Group, Reference, Token}
  alias Pyro.Test.Design.Demo

  defp top_level do
    Spark.Dsl.Extension.get_entities(Demo, [:design])
  end

  defp find(entities, name), do: Enum.find(entities, &(&1.name == name))

  describe "top-level parsing" do
    test "Demo module compiles" do
      assert function_exported?(Demo, :spark_is, 0)
    end

    test "has 3 groups + 3 tokens + 1 modifier at design root" do
      entities = top_level()
      assert length(entities) == 7
      groups = Enum.filter(entities, &is_struct(&1, Group))
      tokens = Enum.filter(entities, &is_struct(&1, Token))
      modifiers = Enum.filter(entities, &is_struct(&1, Pyro.Design.Modifier))
      assert length(groups) == 3
      assert length(tokens) == 3
      assert length(modifiers) == 1

      for name <- [:color, :space, :motion], do: assert(find(groups, name))
      for name <- [:card, :display, :primary_action], do: assert(find(tokens, name))
      assert find(modifiers, :color_mode)
    end
  end

  describe "nested groups" do
    test "color > brand children" do
      color = find(top_level(), :color)
      brand = find(color.children, :brand)
      assert length(brand.children) == 3

      for name <- [:"50", :"500", :"900"] do
        tok = find(brand.children, name)
        assert %Token{type: :color, value: %Color.Oklch{}} = tok
      end
    end

    test "brand has $type at group level" do
      color = find(top_level(), :color)
      brand = find(color.children, :brand)
      assert brand.type == :color
      assert brand.description == "Brand palette."
    end

    test "color > button has parsed $extends ref" do
      color = find(top_level(), :color)
      button = find(color.children, :button)

      assert %Reference{pointer: [:color, :brand], kind: :pointer} = button.extends
    end
  end

  describe "root/2 macro" do
    test "emits a token named :\"$root\" with root?: true" do
      color = find(top_level(), :color)
      accent = find(color.children, :accent)
      assert is_struct(accent, Group)

      root = Enum.find(accent.children, &match?(%Token{name: :"$root"}, &1))
      assert root
      assert root.root? == true
      assert root.type == :color
      assert %Color.Oklch{} = root.value
    end
  end

  describe "ref/2 macro" do
    test "emits a token with a parsed Ref and no value" do
      ref_tok = find(top_level(), :primary_action)
      assert %Token{ref: %Reference{pointer: [:color, :brand, :"500"], kind: :pointer}} = ref_tok
      assert ref_tok.value == nil
    end
  end

  describe "typed macros cover all 13 DTCG types" do
    test "color / oklch string" do
      text = find(find(top_level(), :color).children, :text)
      assert %Color.Oklch{} = text.value
    end

    test "dimension" do
      space = find(top_level(), :space)
      md = find(space.children, :md)
      assert md.value == {1.0, :rem}
      assert md.type == :dimension
    end

    test "duration" do
      motion = find(top_level(), :motion)
      dur = find(motion.children, :duration)
      fast = find(dur.children, :fast)
      assert fast.value == {150.0, :ms}
    end

    test "cubic_bezier" do
      motion = find(top_level(), :motion)
      ease = find(motion.children, :easing)
      std = find(ease.children, :standard)
      assert std.value == {0.2, 0.0, 0.0, 1.0}
    end

    test "shadow" do
      card = find(top_level(), :card)
      assert card.type == :shadow
      assert %{color: %Color.SRGB{}, offset_y: {1.0, :px}} = card.value
    end

    test "typography" do
      display = find(top_level(), :display)
      assert display.type == :typography
      assert display.value.font_family == ["Inter Display", "Inter"]
      assert display.value.font_size == {3.0, :rem}
      assert display.value.font_weight == 800
    end
  end

  describe "icons (top-level sibling of :design)" do
    test "icons section contains declared icons" do
      icons = Spark.Dsl.Extension.get_entities(Demo, [:icons])
      assert length(icons) == 1
      [chevron] = icons
      assert chevron.name == :chevron_down
      assert chevron.svg =~ "<svg viewBox"
    end
  end

  describe "config section" do
    test "namespace" do
      assert Pyro.Design.Info.namespace(Demo) == "demo"
    end
  end

  describe "compile-time validation" do
    test "invalid hex is caught at fixture compile (transform layer)" do
      code = """
      defmodule BadDesign1 do
        use Pyro.Design
        config do
          namespace "bad"
        end
        design do
          color :bogus, "#zzz"
        end
      end
      """

      assert_raise ArgumentError, ~r/invalid color|Invalid hex color|not in the DTCG/, fn ->
        Code.eval_string(code)
      end
    end

    test "non-DTCG Color struct is rejected at compile" do
      code = """
      defmodule BadDesign2 do
        use Pyro.Design
        config do
          namespace "bad"
        end
        design do
          color :bogus, %Color.HSV{h: 0.5, s: 0.5, v: 0.5}
        end
      end
      """

      assert_raise ArgumentError, ~r/not in a DTCG color space/, fn ->
        Code.eval_string(code)
      end
    end

    test "bad dimension unit is caught by Spark schema" do
      code = """
      defmodule BadDesign3 do
        use Pyro.Design
        config do
          namespace "bad"
        end
        design do
          dimension :bogus, 1, :em
        end
      end
      """

      assert_raise ArgumentError, ~r/invalid dimension/, fn ->
        Code.eval_string(code)
      end
    end
  end
end
