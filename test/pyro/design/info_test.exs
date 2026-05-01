defmodule Pyro.Design.InfoTest do
  use ExUnit.Case, async: true

  alias Pyro.Design.{Group, Info, Reference, Token}
  alias Pyro.Test.Design.Demo

  describe "tokens/1" do
    test "indexes all tokens by atom-list path" do
      tokens = Info.tokens(Demo)

      assert %Token{type: :color, value: %Color.Oklch{}} =
               Map.get(tokens, [:color, :brand, :"500"])

      assert %Token{type: :dimension, value: {1.0, :rem}} = Map.get(tokens, [:space, :md])

      assert %Token{type: :shadow, value: %{blur: {2.0, :px}}} = Map.get(tokens, [:card])

      assert %Token{ref: %Reference{pointer: [:color, :brand, :"500"]}} =
               Map.get(tokens, [:primary_action])
    end

    test "includes $root tokens" do
      tokens = Info.tokens(Demo)
      assert %Token{root?: true, name: :"$root"} = Map.get(tokens, [:color, :accent, :"$root"])
    end

    test "count matches fixture" do
      # 2 top-level color + 3 brand + 2 accent + 1 pressed = 8 color-ish
      # + 3 space + 1 duration + 1 easing + 1 shadow + 1 typography + 1 ref = 16
      # + 4 modifier-context tokens (2 light + 2 dark) = 20
      # + 2 default-context (`:light`) unqualified aliases = 22
      assert map_size(Info.tokens(Demo)) == 22
    end

    test "default-context children are also reachable at the unqualified path" do
      tokens = Info.tokens(Demo)

      # Demo has `modifier :color_mode do; default :light; context :light do
      #   color :bg, "#ffffff"; ... end ...end` — the :light context's `:bg`
      # token should be queryable at both the qualified path and the
      # unqualified path so component CSS can reference `$bg` / `$text`.
      assert %Token{name: :bg} = Map.get(tokens, [:color_mode, :light, :bg])
      assert %Token{name: :bg} = Map.get(tokens, [:bg])
      assert %Token{name: :text} = Map.get(tokens, [:text])

      # The unqualified alias points at the default context's value.
      assert Map.get(tokens, [:bg]).value == Map.get(tokens, [:color_mode, :light, :bg]).value
    end
  end

  describe "type_map/1" do
    test "resolves inline types" do
      type_map = Info.type_map(Demo)
      assert type_map[[:card]] == :shadow
      assert type_map[[:display]] == :typography
    end

    test "inherits type from ancestor group" do
      type_map = Info.type_map(Demo)
      # brand group sets type: :color -> children inherit
      assert type_map[[:color, :brand, :"500"]] == :color
      # space group sets type: :dimension
      assert type_map[[:space, :md]] == :dimension
      # motion.duration sets type: :duration
      assert type_map[[:motion, :duration, :fast]] == :duration
      # motion.easing sets type: :cubic_bezier
      assert type_map[[:motion, :easing, :standard]] == :cubic_bezier
    end

    test "ref-only tokens have nil type" do
      type_map = Info.type_map(Demo)
      assert type_map[[:primary_action]] == nil
    end
  end

  describe "refs/1" do
    test "collects both token $ref and group $extends" do
      refs = Info.refs(Demo)

      # token $ref
      assert %Reference{pointer: [:color, :brand, :"500"]} = Map.get(refs, [:primary_action])

      # group $extends
      assert %Reference{pointer: [:color, :brand]} = Map.get(refs, [:color, :button])
    end
  end

  describe "tree/1 and at/2" do
    test "tree/1 returns a synthetic root group" do
      tree = Info.tree(Demo)
      assert %Group{name: :__root__} = tree
      assert is_list(tree.children)
      assert length(tree.children) == 7
    end

    test "at/2 with token path" do
      assert %Token{type: :dimension} = Info.at(Demo, [:space, :md])
    end

    test "at/2 with group path" do
      assert %Group{name: :brand, description: "Brand palette."} =
               Info.at(Demo, [:color, :brand])
    end

    test "at/2 with unknown path" do
      assert Info.at(Demo, [:nope]) == nil
    end
  end

  describe "icons" do
    test "icon_map/1" do
      assert %{chevron_down: svg} = Info.icon_map(Demo)
      assert svg =~ "<svg"
    end

    test "icons/1 / icon/2 / icon_names/1" do
      assert [icon] = Info.icons(Demo)
      assert icon.name == :chevron_down
      assert Info.icon(Demo, :chevron_down) == icon
      assert Info.icon_names(Demo) == [:chevron_down]
    end
  end

  describe "module-level output options" do
    test "defaults are nil/false when not set" do
      assert Info.css_output(Demo) == nil
      assert Info.json_output(Demo) == nil
      assert Info.support_tailwind?(Demo) == false
      assert Info.manage_base_layer?(Demo) == false
    end

    test "options round-trip through use Pyro.Design opts" do
      code = """
      defmodule Pyro.Test.Design.Outputs do
        use Pyro.Design,
          css_output: "out.css",
          json_output: "out.json",
          support_tailwind?: true,
          manage_base_layer?: true

        config do
          namespace "outputs"
        end

        design do
          color :brand, "#ff0000"
        end
      end
      """

      Code.eval_string(code)
      mod = Pyro.Test.Design.Outputs

      assert Info.css_output(mod) == "out.css"
      assert Info.json_output(mod) == "out.json"
      assert Info.support_tailwind?(mod) == true
      assert Info.manage_base_layer?(mod) == true
    end
  end

  describe "static helpers" do
    test "types/0" do
      types = Info.types()
      assert :color in types
      assert :typography in types
    end

    test "color_spaces/0 lists 14 DTCG spaces" do
      spaces = Info.color_spaces()
      assert length(spaces) == 14
      assert :srgb in spaces
      assert :oklch in spaces
    end
  end
end
