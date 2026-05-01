defmodule Pyro.Design.ColorParseTest do
  use ExUnit.Case, async: true

  alias Pyro.Design.Value.Color, as: Parser

  describe "parse/1 string inputs (via Color.CSS.parse/1)" do
    test "hex long" do
      assert {:ok, %Color.SRGB{r: 1.0, g: +0.0, b: 1.0}} = Parser.parse("#ff00ff")
    end

    test "hex short" do
      assert {:ok, %Color.SRGB{r: 1.0, g: +0.0, b: 1.0}} = Parser.parse("#f0f")
    end

    test "hex with alpha" do
      assert {:ok, %Color.SRGB{alpha: alpha}} = Parser.parse("#ff000080")
      assert_in_delta alpha, 128 / 255, 0.001
    end

    test "CSS named color" do
      assert {:ok, %Color.SRGB{}} = Parser.parse("rebeccapurple")
    end

    test "CSS oklch() function" do
      assert {:ok, %Color.Oklch{l: 0.7, c: 0.25, h: 328.0}} = Parser.parse("oklch(0.7 0.25 328)")
    end

    test "CSS rgb() with alpha" do
      assert {:ok, %Color.SRGB{alpha: 0.5}} = Parser.parse("rgb(255 0 0 / 50%)")
    end

    test "CSS lab() function" do
      assert {:ok, %Color.Lab{}} = Parser.parse("lab(50% 40 30)")
    end

    test "CSS color(display-p3 ...)" do
      assert {:ok, %Color.RGB{working_space: :P3_D65}} = Parser.parse("color(display-p3 1 0 1)")
    end

    test "unknown string errors" do
      assert {:error, _} = Parser.parse("not a color")
    end
  end

  describe "parse/1 Color struct passthrough" do
    test "Color.SRGB" do
      color = %Color.SRGB{r: 0.5, g: 0.5, b: 0.5}
      assert {:ok, ^color} = Parser.parse(color)
    end

    test "Color.Oklch" do
      color = %Color.Oklch{l: 0.7, c: 0.25, h: 328}
      assert {:ok, ^color} = Parser.parse(color)
    end

    test "Color.RGB with DTCG-allowed working_space" do
      for ws <- [:SRGB, :P3_D65, :Adobe, :ProPhoto, :Rec2020] do
        color = %Color.RGB{r: 0.5, g: 0.5, b: 0.5, working_space: ws}
        assert {:ok, ^color} = Parser.parse(color)
      end
    end

    test "Color.XYZ with D50 / D65 illuminant" do
      for ill <- [:D50, :D65] do
        color = %Color.XYZ{x: 0.5, y: 0.5, z: 0.5, illuminant: ill, observer_angle: 2}
        assert {:ok, ^color} = Parser.parse(color)
      end
    end

    test "non-DTCG Color struct rejected" do
      color = %Color.HSV{h: 0.5, s: 0.5, v: 0.5}
      assert {:error, msg} = Parser.parse(color)
      assert msg =~ "not in a DTCG color space"
    end

    test "Color.XYZ with non-DTCG illuminant rejected" do
      color = %Color.XYZ{x: 0.5, y: 0.5, z: 0.5, illuminant: :D55, observer_angle: 2}
      assert {:error, msg} = Parser.parse(color)
      assert msg =~ ":D55"
      assert msg =~ ":D50"
      assert msg =~ ":D65"
    end

    test "Color.RGB with non-DTCG working_space rejected" do
      color = %Color.RGB{r: 0.5, g: 0.5, b: 0.5, working_space: :Rec709}
      assert {:error, msg} = Parser.parse(color)
      assert msg =~ ":Rec709"
    end
  end

  describe "parse/1 unsupported inputs" do
    test "tagged tuple rejected" do
      assert {:error, msg} = Parser.parse({:oklch, [0.7, 0.25, 328]})
      assert msg =~ "must be a CSS string or a Color.t() struct"
    end

    test "DTCG keyword form rejected" do
      assert {:error, msg} = Parser.parse(color_space: :oklch, components: [0.7, 0.25, 328])
      assert msg =~ "must be a CSS string or a Color.t() struct"
    end

    test "atom rejected" do
      assert {:error, _} = Parser.parse(:rebeccapurple)
    end

    test "number rejected" do
      assert {:error, _} = Parser.parse(42)
    end
  end

  describe "parse!/1" do
    test "returns value on success" do
      assert %Color.Oklch{} = Parser.parse!("oklch(0.7 0.25 328)")
    end

    test "raises on failure" do
      assert_raise ArgumentError, ~r/invalid color/, fn ->
        Parser.parse!({:oklch, [0.7, 0.25, 328]})
      end
    end
  end

  describe "dtcg_color_spaces/0" do
    test "lists 14 spec spaces" do
      spaces = Parser.dtcg_color_spaces()
      assert length(spaces) == 14
      assert :srgb in spaces
      assert :hwb in spaces
      assert :oklch in spaces
      assert :xyz_d50 in spaces
    end
  end
end
