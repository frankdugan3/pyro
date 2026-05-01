defmodule Pyro.Design.ModifierTest do
  use ExUnit.Case, async: true

  alias Pyro.Design.{Context, Info, Modifier, Token}
  alias Pyro.Test.Design.Demo

  describe "Demo fixture modifier" do
    test "modifiers/1 exposes the declared modifier" do
      modifiers = Info.modifiers(Demo)
      assert %Modifier{name: :color_mode, default: :light} = Map.get(modifiers, [:color_mode])
    end

    test "contexts/1 exposes both contexts" do
      contexts = Info.contexts(Demo)
      assert %Context{name: :light} = Map.get(contexts, [:color_mode, :light])
      assert %Context{name: :dark} = Map.get(contexts, [:color_mode, :dark])
    end

    test "context tokens indexed by full path" do
      tokens = Info.tokens(Demo)
      assert %Token{type: :color, name: :bg} = Map.get(tokens, [:color_mode, :light, :bg])
      assert %Token{type: :color, name: :bg} = Map.get(tokens, [:color_mode, :dark, :bg])
    end
  end

  describe "validation" do
    defp compile(body) do
      code = """
      defmodule PyroDesignModifierTest.M#{System.unique_integer([:positive])} do
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

      assert %Spark.Error.DslError{} = exc,
             "expected a Spark.Error.DslError, got: #{inspect(exc)}"

      assert Exception.message(exc) =~ pattern
    end

    test "modifier with zero contexts errors" do
      assert_dsl_error(
        """
        modifier :mode do
          default :light
        end
        """,
        "DTCG requires at least 2"
      )
    end

    test "modifier with one context errors" do
      assert_dsl_error(
        """
        modifier :mode do
          context :only do
            color :bg, "#fff"
          end
        end
        """,
        "DTCG requires at least 2"
      )
    end

    test "happy path: two contexts compiles" do
      # No error expected.
      compile("""
      modifier :mode do
        default :light

        context :light do
          color :bg, "#fff"
        end

        context :dark do
          color :bg, "#000"
        end
      end
      """)
    end

    test "default naming a non-existent context errors" do
      assert_dsl_error(
        """
        modifier :mode do
          default :missing

          context :light do
            color :bg, "#fff"
          end

          context :dark do
            color :bg, "#000"
          end
        end
        """,
        ~r/default context :missing/
      )
    end

    test "context children with an unresolvable ref errors" do
      assert_dsl_error(
        """
        modifier :mode do
          context :light do
            ref :bg, "#/does/not/exist"
          end

          context :dark do
            color :bg, "#000"
          end
        end
        """,
        "does not resolve"
      )
    end

    test "context children with a resolvable ref passes" do
      compile("""
      color :brand, "#ff0000"

      modifier :mode do
        context :light do
          ref :bg, "#/brand"
        end

        context :dark do
          color :bg, "#000"
        end
      end
      """)
    end
  end
end
