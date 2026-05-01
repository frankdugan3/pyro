defmodule Pyro.Design.ValidateTreeTest do
  use ExUnit.Case, async: true

  # Each test compiles a fresh Pyro.Design module and expects a DslError
  # with a specific message. Modules are defined inside `Code.eval_string`
  # to contain the raise.

  defp compile(body) do
    code = """
    defmodule PyroDesignValidateTest.M#{System.unique_integer([:positive])} do
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

  defp assert_dsl_error(body, pattern) do
    exc =
      try do
        compile(body)
        nil
      rescue
        e -> e
      end

    assert %Spark.Error.DslError{} = exc, "expected a Spark.Error.DslError, got: #{inspect(exc)}"
    assert Exception.message(exc) =~ pattern
  end

  describe "token/ref mutual exclusion" do
    test "neither value nor ref" do
      assert_dsl_error(
        """
        token :foo, type: :color
        """,
        "must set either :value or :ref"
      )
    end

    test "both value and ref" do
      assert_dsl_error(
        """
        token :foo,
          type: :color,
          value: %Color.SRGB{r: 1.0, g: 1.0, b: 1.0},
          ref: Pyro.Design.Reference.parse!("#/color/bg")

        color :bg, "#ffffff"
        """,
        "must not set both :value and :ref"
      )
    end
  end

  describe "type resolution" do
    test "token with no type and no ancestor type fails" do
      assert_dsl_error(
        """
        token :foo, value: "bogus"
        """,
        "has no $type"
      )
    end

    test "unknown type fails (Spark schema rejection)" do
      # Spark's schema validation rejects an unknown `:type` option
      # before our ValidateTree transformer runs. The message includes
      # the list of valid types.
      assert_raise Spark.Error.DslError, ~r/invalid value for :type option/, fn ->
        compile("""
        token :foo, type: :colour, value: "anything"
        """)
      end
    end

    test "type inherited from ancestor group passes" do
      # No error expected.
      compile("""
      group :g do
        type :color

        token :brand, value: %Color.SRGB{r: 1.0, g: 0.0, b: 0.0}
      end
      """)
    end
  end

  describe "$ref / $extends target resolution" do
    test "dangling token $ref errors" do
      assert_dsl_error(
        """
        ref :alias, "#/nope/missing"
        """,
        "does not resolve to a local token or group"
      )
    end

    test "dangling group $extends errors" do
      assert_dsl_error(
        """
        group :g do
          extends "#/nope/missing"

          color :foo, "#ff0000"
        end
        """,
        "does not resolve to a local group"
      )
    end

    test "valid $ref passes" do
      compile("""
      color :brand, "#ff0000"
      ref :primary, "#/brand"
      """)
    end
  end

  describe "$root rules" do
    test "$root at top level of design errors" do
      assert_dsl_error(
        """
        root :color, "#ff0000"
        """,
        "$root token only valid inside a group"
      )
    end

    test "multiple $root tokens in one group errors" do
      assert_dsl_error(
        """
        group :g do
          root :color, "#ff0000"
          root :color, "#00ff00"
        end
        """,
        ~r/(at most one allowed|duplicate sibling name)/
      )
    end
  end

  describe "sibling uniqueness" do
    test "case-only duplicate siblings errors" do
      assert_dsl_error(
        """
        color :foo, "#ff0000"
        color :Foo, "#00ff00"
        """,
        "differ only by case"
      )
    end
  end
end
