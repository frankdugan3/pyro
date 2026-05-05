defmodule Pyro.Design.Skill.WriterTest do
  use ExUnit.Case, async: true

  alias Pyro.Design.Skill.Writer
  alias Pyro.Test.Design.Demo

  setup_all do
    {:ok, files: Writer.build(Demo)}
  end

  describe "build/1 — file map" do
    test "emits exactly the four expected paths under the namespaced design dir", %{files: files} do
      assert Map.keys(files) |> Enum.sort() == Enum.sort(Writer.files(Demo))

      for rel <- Map.keys(files) do
        assert String.starts_with?(rel, "demo-design/"),
               "expected #{rel} to live under demo-design/"
      end
    end

    test "every file is a non-empty string", %{files: files} do
      for {rel, content} <- files do
        assert is_binary(content), "#{rel} is not a binary"
        assert String.trim(content) != "", "#{rel} is empty"
      end
    end
  end

  describe "demo-design/SKILL.md" do
    setup %{files: files}, do: %{md: files["demo-design/SKILL.md"]}

    test "frontmatter `name` matches the directory name", %{md: md} do
      assert md =~ ~r/\A---\nname: demo-design\ndescription: /
    end

    test "names the design module in the description", %{md: md} do
      assert md =~ "Pyro.Test.Design.Demo"
    end

    test "documents the namespace", %{md: md} do
      assert md =~ "CSS namespace: `demo`"
      assert md =~ "var(--demo-<dashed-path>)"
    end

    test "shows the colocated CSS wrapper pattern", %{md: md} do
      assert md =~ "use Pyro.LiveView.ColocatedCSS, design: Pyro.Test.Design.Demo"
      assert md =~ ~r/<style :type=\{MyAppWeb\.ColocatedCSS\}>/
    end

    test "documents the validator rules", %{md: md} do
      assert md =~ "$dotted.token.path"
      assert md =~ "@media"
      assert md =~ "literal"
      assert md =~ "Raw `var(--demo-…)` is rejected"
    end

    test "uses kebab-case in the modifier example attribute", %{md: md} do
      # Demo declares `:color_mode` — must render as `data-color-mode`, never with underscore.
      assert md =~ ~s|data-color-mode=|
      refute md =~ ~s|data-color_mode|
    end

    test "tells the LLM to prefer a project icon component", %{md: md} do
      assert md =~ "Prefer the project's icon component"
    end

    test "links to the sibling reference files", %{md: md} do
      assert md =~ "./tokens.md"
      assert md =~ "./modifiers.md"
      assert md =~ "./icons.md"
      refute md =~ "../shared/"
    end

    test "covers customizing the design", %{md: md} do
      assert md =~ "# Customizing the design"
      assert md =~ "test/support/design/demo.ex"
      assert md =~ "### Add a token"
      assert md =~ "### Add a group"
      assert md =~ "### Reference / alias another token"
      assert md =~ "### Add a modifier or context"
      assert md =~ "### Add an icon"
      assert md =~ "### Compose another design"
    end

    test "lists DSL output options including generate_skills?", %{md: md} do
      assert md =~ ":generate_skills?"
      assert md =~ ":json_output"
      assert md =~ ":css_output"
    end
  end

  describe "demo-design/tokens.md" do
    setup %{files: files}, do: %{md: files["demo-design/tokens.md"]}

    test "headers the namespace", %{md: md} do
      assert md =~ "Namespace: `demo`"
    end

    test "renders Color section with brand and accent rows", %{md: md} do
      assert md =~ "## Color"
      assert md =~ "`color.bg`"
      assert md =~ "`color.brand.500`"
      assert md =~ "`color.accent.hover`"
    end

    test "renders Dimension section with space tokens", %{md: md} do
      assert md =~ "## Dimension"
      assert md =~ "`space.md`"
      assert md =~ "0.25rem"
    end

    test "renders Duration and Cubic bezier sections", %{md: md} do
      assert md =~ "## Duration"
      assert md =~ "`motion.duration.fast`"
      assert md =~ "150ms"
      assert md =~ "## Cubic bezier"
      assert md =~ "`motion.easing.standard`"
      assert md =~ "cubic-bezier"
    end

    test "renders Shadow section", %{md: md} do
      assert md =~ "## Shadow"
      assert md =~ "`card`"
    end

    test "renders Typography section with composite formatting", %{md: md} do
      assert md =~ "## Typography"
      assert md =~ "`display`"
      assert md =~ "Inter Display"
      assert md =~ "weight 800"
    end

    test "modifier-scoped paths do not appear in the main token tables", %{md: md} do
      refute md =~ ~s|`color_mode.|
      refute md =~ "## Color_mode"
    end

    test "Aliases section lists token-level $ref and group-level $extends", %{md: md} do
      assert md =~ "## Aliases"
      assert md =~ "`primary_action`"
      assert md =~ "`color.brand.500`"
      assert md =~ "`color.button`"
      assert md =~ "`color.brand`"
    end
  end

  describe "demo-design/modifiers.md" do
    setup %{files: files}, do: %{md: files["demo-design/modifiers.md"]}

    test "headers the design", %{md: md} do
      assert md =~ "# `Pyro.Test.Design.Demo` — Modifiers"
    end

    test "renders the color_mode section with description and default toggle", %{md: md} do
      assert md =~ "## `color_mode` — Light vs dark mode."
      assert md =~ "Default context: `light`"
      assert md =~ ~s|<html data-color-mode="dark">|
    end

    test "tabulates re-bound tokens across contexts", %{md: md} do
      assert md =~ "Re-bound tokens:"
      assert md =~ "| Token re-bound | `light` | `dark` |"
      assert md =~ ~r/\| `bg` \| `rgb\(255 255 255\)` \| `rgb\(10 10 10\)` \|/
    end
  end

  describe "demo-design/icons.md" do
    setup %{files: files}, do: %{md: files["demo-design/icons.md"]}

    test "advises preferring the project icon component", %{md: md} do
      assert md =~ "If the project ships an icon component"
    end

    test "renders the namespaced raw selector", %{md: md} do
      assert md =~ ~s|<span data-demo-icon="<name>" />|
    end

    test "lists the design's icon names", %{md: md} do
      assert md =~ "- `chevron_down`"
    end
  end

  describe "build/1 — empty design (no modifiers, no icons)" do
    defmodule Tiny do
      @moduledoc false
      use Pyro.Design

      config do
        namespace "tiny"
      end

      design do
        color :bg, "#ffffff"
      end
    end

    setup do
      {:ok, files: Writer.build(Tiny)}
    end

    test "still emits all four files under the namespaced dir", %{files: files} do
      assert Map.keys(files) |> Enum.sort() == Enum.sort(Writer.files(Tiny))
      assert Enum.all?(Map.keys(files), &String.starts_with?(&1, "tiny-design/"))
    end

    test "modifiers.md notes the absence", %{files: files} do
      assert files["tiny-design/modifiers.md"] =~ "_No modifiers declared._"
    end

    test "icons.md notes the absence", %{files: files} do
      assert files["tiny-design/icons.md"] =~ "_No icons declared._"
    end
  end
end
