defmodule Pyro.Design.CSS.WriterTest do
  use ExUnit.Case, async: true

  alias Pyro.Design.CSS.Writer

  defmodule Fixture do
    use Pyro.Design,
      support_tailwind?: true,
      manage_base_layer?: true

    config do
      namespace "test"
      tailwind_preamble "/* preamble */"

      base_layer do
        selector ["html", "body"] do
          property "margin", "0"
        end

        raw("""
        @keyframes flash {
          0% { background: $bg; }
          100% { background: transparent; }
        }
        """)
      end
    end

    design do
      color(:bg, "#ffffff")
      dimension(:spacing_md, 1.0, :rem)

      shadow :card do
        color("#0003")
        offset_x(0, :px)
        offset_y(1, :px)
        blur(2, :px)
        spread(0, :px)
      end

      modifier :color_mode do
        default :light

        extensions(%{
          "pm.hex.pyro.css" => %{
            "selector_template" => "[data-{modifier}=\"{context}\"]",
            "media_query_fallback" => "@media (prefers-color-scheme: {context})"
          }
        })

        context :light do
          color(:surface, "#ffffff")
        end

        context :dark do
          color(:surface, "#0a0a0a")
        end
      end

      modifier :density do
        default :comfortable

        context :comfortable do
          dimension(:gap, 1.0, :rem)
        end

        context :compact do
          dimension(:gap, 0.5, :rem)
        end
      end

      modifier :scheme do
        default :light

        context :light do
          group :color do
            group :primary do
              color(:base, "#dbeafe")
              color(:contrast, "#1d4ed8")
            end
          end
        end

        context :dark do
          group :color do
            group :primary do
              color(:base, "#0c1a2e")
              color(:contrast, "#3b82f6")
            end
          end
        end
      end
    end

    icons do
      icon :star, ~SVG"""
      <svg viewBox="0 0 24 24"><path d="M12 2l3 7h7l-5.5 4.5L18 22l-6-4-6 4 1.5-8.5L2 9h7z"/></svg>
      """
    end
  end

  setup do
    {:ok, css: Writer.build(Fixture)}
  end

  test "emits :root containing top-level token vars", %{css: css} do
    assert css =~ ":root {"
    assert css =~ "--test-bg:"
    assert css =~ "--test-spacing-md: 1rem;"
  end

  test "color tokens render as CSS color strings", %{css: css} do
    assert css =~ ~r/--test-bg:\s*(#ffffff|rgb|oklch|hsl)/
  end

  test "dimension drops .0 on whole numbers", %{css: css} do
    assert css =~ "--test-spacing-md: 1rem;"
    refute css =~ "--test-spacing-md: 1.0rem;"
  end

  test "shadow renders as box-shadow shorthand string", %{css: css} do
    assert css =~ "--test-card: 0px 1px 2px 0px"
  end

  test "default modifier context contributes to :root", %{css: css} do
    [root_block] = Regex.run(~r/:root \{([^}]+)\}/, css, capture: :all_but_first)
    assert root_block =~ "--test-surface:"
    assert root_block =~ "--test-gap: 1rem;"
  end

  test "non-default context emits a data-attribute selector block with overrides only", %{
    css: css
  } do
    assert css =~ ~r/\[data-color_mode="dark"\]\s*\{[^}]*--test-surface:[^}]*\}/
    assert css =~ ~r/\[data-density="compact"\]\s*\{[^}]*--test-gap: 0\.5rem;[^}]*\}/
  end

  test "media-query fallback emits when configured", %{css: css} do
    assert css =~ ~r/@media \(prefers-color-scheme: dark\)\s*\{/
  end

  test "no media query block when none configured for that modifier", %{css: css} do
    refute css =~ "prefers-color-scheme: compact"
  end

  test "tailwind preamble appears verbatim", %{css: css} do
    assert css =~ "/* preamble */"
  end

  test "@theme block maps recognized token paths to Tailwind namespaces, referencing :root vars",
       %{
         css: css
       } do
    [theme_block] = Regex.run(~r/@theme \{([^}]+)\}/, css, capture: :all_but_first)

    # `[:color, :primary, :base]` (an unqualified alias of the :scheme
    # modifier's default :light context) maps to Tailwind's --color-* namespace
    # and references the namespaced root var.
    assert theme_block =~ "--color-primary-base: var(--test-color-primary-base);"
    assert theme_block =~ "--color-primary-contrast: var(--test-color-primary-contrast);"

    # Top-level tokens that don't fit a Tailwind namespace are skipped —
    # they remain available as `--test-*` vars on `:root` (and so usable
    # as raw CSS variables) but don't get exposed as Tailwind utility tokens.
    refute theme_block =~ "--test-bg"
    refute theme_block =~ "--test-spacing-md"
  end

  test "modifier with nested groups inside contexts emits full dashed paths", %{css: css} do
    expected_dark_block = """
    [data-scheme="dark"] {
      --test-color-primary-base: rgb(12 26 46);
      --test-color-primary-contrast: rgb(59 130 246);
    }\
    """

    assert String.contains?(css, expected_dark_block)
  end

  test "@layer base block emits config.base_layer selectors", %{css: css} do
    assert css =~ "@layer base {"
    [layer] = Regex.run(~r/@layer base \{((?:[^{}]|\{[^}]*\})*)\}/, css, capture: :all_but_first)
    assert layer =~ "html, body"
    assert layer =~ "margin: 0"
  end

  test "raw entity emits CSS verbatim with $ref resolved to var()", %{css: css} do
    expected = """
      @keyframes flash {
        0% { background: var(--test-bg); }
        100% { background: transparent; }
      }\
    """

    assert String.contains?(css, expected)
  end

  test "icons emit [data-{namespace}-icon] mask-image rules", %{css: css} do
    assert css =~ ~s([data-test-icon="star"] {)
    assert css =~ "mask-image: url(\"data:image/svg+xml,"
    # SVG content is URL-encoded: quotes become single quotes, # → %23
    assert css =~ "<svg viewBox='0 0 24 24'>"
  end
end
