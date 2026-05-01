defmodule Pyro.LiveView.ColocatedCSSTest do
  use ExUnit.Case, async: true

  alias Pyro.LiveView.ColocatedCSS
  alias Pyro.Test.Design.Demo

  @meta %{module: __MODULE__, file: __ENV__.file, line: 1}

  describe "use without :design" do
    test "raises a CompileError pointing at the required option" do
      assert_raise CompileError, ~r/requires a `:design` option/, fn ->
        defmodule MissingDesignWrapper do
          use Pyro.LiveView.ColocatedCSS
        end
      end
    end
  end

  describe "raw namespaced var() rejection" do
    test "raises listing every offending namespaced var() occurrence" do
      css = """
      .a { color: var(--demo-color-brand-500); }
      .b { background: var(--demo-space-md); }
      """

      assert_raise CompileError, ~r/raw `var\(--demo-…\)` is not allowed/, fn ->
        ColocatedCSS.__transform__("style", %{}, css, @meta, Demo)
      end
    end

    test "passes when no namespaced var() is present" do
      css = ".btn { color: $color.brand.500; }"
      assert {:ok, _, []} = ColocatedCSS.__transform__("style", %{}, css, @meta, Demo)
    end

    test "allows local component vars that are not in the design's namespace" do
      css = """
      .btn {
        --bg: $color.brand.500;
        --fg: $color.brand.50;
        background: var(--bg);
        color: var(--fg);
      }
      """

      assert {:ok, _, []} = ColocatedCSS.__transform__("style", %{}, css, @meta, Demo)
    end
  end

  describe "ref validation" do
    test "raises listing every unknown ref" do
      css = ".btn { color: $color.nope; padding: $space.also_missing; }"

      assert_raise CompileError, ~r/unknown design token references/, fn ->
        ColocatedCSS.__transform__("style", %{}, css, @meta, Demo)
      end
    end

    test "accepts refs that exist in the design" do
      css = ".btn { color: $color.brand.500; padding: $space.md; }"
      assert {:ok, _, []} = ColocatedCSS.__transform__("style", %{}, css, @meta, Demo)
    end
  end

  describe "substitution" do
    test "non-media refs lower to var() with the design's namespace" do
      css = ".btn { color: $color.brand.500; padding: $space.md; }"

      {:ok, out, []} = ColocatedCSS.__transform__("style", %{}, css, @meta, Demo)

      assert out =~ "var(--demo-color-brand-500)"
      assert out =~ "var(--demo-space-md)"
    end

    test "underscores in token atom names lower to dashes in the var name" do
      css = ".btn { padding: $space.squish_block; }"

      {:ok, out, []} = ColocatedCSS.__transform__("style", %{}, css, @meta, Demo)

      assert out =~ "var(--demo-space-squish-block)"
      refute out =~ "squish_block"
    end

    test "refs inside @media query conditions resolve to literal values" do
      css = "@media (min-width: $space.md) { .btn { padding: $space.xs; } }"

      {:ok, out, []} = ColocatedCSS.__transform__("style", %{}, css, @meta, Demo)

      assert out =~ "@media (min-width: 1rem)"
      # Body of the media query still uses var()
      assert out =~ "var(--demo-space-xs)"
    end

    test "literal substitution in @media leaves non-@media refs as vars" do
      css = """
      .btn { padding: $space.md; }
      @media (min-width: $space.md) { .btn { padding: $space.xs; } }
      """

      {:ok, out, []} = ColocatedCSS.__transform__("style", %{}, css, @meta, Demo)

      # Outer rule keeps var()
      assert out =~ ~r/\.btn \{ padding: var\(--demo-space-md\); \}/
      # @media condition uses literal
      assert out =~ "@media (min-width: 1rem)"
    end
  end
end
