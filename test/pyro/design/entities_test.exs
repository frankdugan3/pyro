defmodule Pyro.Design.EntitiesTest do
  use ExUnit.Case, async: true

  # Compile-time validation of each per-type entity. Positive cases
  # (entity compiles into a token in the design tree) and negative
  # cases (Spark schema rejection on bad opts).

  defp compile(body) do
    code = """
    defmodule PyroDesignEntitiesTest.M#{System.unique_integer([:positive])} do
      use Pyro.Design

      config do
        namespace "test"
      end

      design do
        #{body}
      end
    end
    """

    Code.eval_string(code)
  end

  # Macro-expansion failures surface as ArgumentError (from
  # `Pyro.Design.Value.*.parse!/1`); schema-level failures on the
  # canonical entities (token, group, modifier, context) surface as
  # Spark.Error.DslError. Accept either, pattern-match the message.
  defp assert_raises(body, _ignored_expected, pattern) do
    err =
      try do
        compile(body)
        nil
      rescue
        e -> e
      end

    assert err, "expected an exception but compile succeeded"

    msg =
      case err do
        %ArgumentError{message: m} -> m
        %Spark.Error.DslError{} -> Exception.message(err)
        other -> Exception.message(other)
      end

    assert msg =~ pattern,
           "expected message to match #{inspect(pattern)}, got: #{msg}"
  end

  describe "color" do
    test "string input compiles" do
      compile(~s|color :brand, "#ff00ff"|)
    end

    test "Color struct passthrough compiles" do
      compile(~s|color :brand, %Color.SRGB{r: 1.0, g: 0.0, b: 1.0}|)
    end

    test "tuple form is rejected by the parser at compile" do
      assert_raises(
        ~s|color :brand, {:oklch, [0.7, 0.25, 328]}|,
        Spark.Error.DslError,
        ~r/must be a CSS string or a Color.t\(\) struct/
      )
    end
  end

  describe "dimension" do
    test "valid units compile" do
      compile("dimension :md, 1.0, :rem")
      compile("dimension :sm, 4, :px")
    end

    test "invalid unit rejected" do
      assert_raises(
        "dimension :bad, 1, :em",
        ArgumentError,
        ~r/invalid dimension/
      )
    end

    test "non-number scalar rejected" do
      assert_raises(
        ~s|dimension :bad, "1", :px|,
        ArgumentError,
        ~r/invalid dimension/
      )
    end
  end

  describe "duration" do
    test "valid units compile" do
      compile("duration :fast, 150, :ms")
      compile("duration :slow, 1, :s")
    end

    test "invalid unit rejected" do
      assert_raises(
        "duration :bad, 1, :seconds",
        ArgumentError,
        ~r/invalid duration/
      )
    end
  end

  describe "font_weight" do
    test "integer in range compiles" do
      compile("font_weight :body, 400")
    end

    test "alias resolves at compile" do
      compile("font_weight :heading, :bold")
    end

    test "out-of-range integer rejected" do
      assert_raises(
        "font_weight :bad, 1500",
        ArgumentError,
        ~r/invalid font_weight/
      )
    end

    test "unknown alias rejected" do
      assert_raises(
        "font_weight :bad, :super_ultra",
        Spark.Error.DslError,
        ~r/font_weight alias :super_ultra unknown/
      )
    end
  end

  describe "cubic_bezier" do
    test "tuple form compiles" do
      compile("cubic_bezier :standard, {0.2, 0.0, 0.0, 1.0}")
    end

    test "x-coordinate out of [0,1] rejected" do
      assert_raises(
        "cubic_bezier :bad, {1.5, 0.0, 0.0, 1.0}",
        Spark.Error.DslError,
        ~r/P1x must be in \[0, 1\]/
      )
    end
  end

  describe "shadow (composite)" do
    test "happy path" do
      compile("""
      shadow :card do
        color "#0003"
        offset_x {0, :px}
        offset_y {1, :px}
        blur {2, :px}
        spread {0, :px}
      end
      """)
    end

    test "missing required field rejected" do
      assert_raises(
        """
        shadow :card do
          color "#0003"
          offset_x {0, :px}
        end
        """,
        ArgumentError,
        ~r/missing required keys/
      )
    end

    test "bad sub-value (color) surfaces" do
      assert_raises(
        """
        shadow :card do
          color "not-a-color"
          offset_x {0, :px}
          offset_y {0, :px}
          blur {0, :px}
          spread {0, :px}
        end
        """,
        Spark.Error.DslError,
        ~r/Unknown CSS color name/
      )
    end
  end

  describe "typography (composite)" do
    test "happy path with optional line_height" do
      compile("""
      typography :display do
        font_family ["Inter", "system-ui"]
        font_size {3.0, :rem}
        font_weight 800
        line_height 1.05
      end
      """)
    end

    test "missing font_weight rejected" do
      assert_raises(
        """
        typography :bad do
          font_family ["Inter"]
          font_size {1, :rem}
        end
        """,
        ArgumentError,
        ~r/missing required keys.*font_weight/
      )
    end
  end

  describe "ref" do
    test "valid pointer compiles" do
      compile("""
      color :brand, "#ff0000"
      ref :primary, "#/brand"
      """)
    end

    test "malformed pointer rejected" do
      assert_raises(
        ~s|ref :alias, "not-a-pointer"|,
        Spark.Error.DslError,
        ~r/JSON Pointer/
      )
    end
  end

  describe "root" do
    test "color $root compiles inside a group" do
      compile("""
      group :accent do
        root :color, "#00ff00"
      end
      """)
    end

    test "dimension $root compiles" do
      compile("""
      group :sizing do
        root :dimension, {1.0, :rem}
      end
      """)
    end

    test "composite types not allowed via root" do
      assert_raises(
        """
        group :wrap do
          root :shadow, "anything"
        end
        """,
        ArgumentError,
        ~r/invalid shadow|shadow expects a keyword list/
      )
    end
  end
end
