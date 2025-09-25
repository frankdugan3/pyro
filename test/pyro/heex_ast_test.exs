defmodule Pyro.HEEx.ASTTest do
  use ExUnit.Case, async: true

  import Pyro.HEEx.AST

  alias Pyro.HEEx.AST

  doctest AST, import: true

  describe "parse_template/1 whitespace and comments" do
    test "preserves whitespace in templates" do
      template = """
      <div>
        <p>Hello World</p>
        <span>  Multiple spaces  </span>
      </div>
      """

      assert template |> parse_template!() |> Map.get(:nodes) |> encode_nodes() == template
    end

    test "preserves HTML comments" do
      template = """
      <!-- This is a comment -->
      <div>
        <!-- Another comment -->
        <p>Content</p>
      </div>
      """

      %AST{nodes: nodes} = parse_template!(template)

      assert Enum.any?(nodes, fn
               {:comment, _} -> true
               _ -> false
             end)

      assert encode_nodes(nodes) == template
    end

    test "preserves multiline comments" do
      template = """
      <!--
        This is a multiline comment
        with multiple lines
      -->
      <div>Content</div>
      """

      assert template |> parse_template!() |> Map.get(:nodes) |> encode_nodes() == template
    end

    test "parses comments with special characters" do
      template = """
      <!-- TODO: Add validation for email & phone -->
      <form>
        <!-- @deprecated: Use new input component -->
        <input type="text" />
      </form>
      """

      assert template |> parse_template!() |> Map.get(:nodes) |> encode_nodes() == template
    end

    test "preserves indentation and newlines" do
      template = """
      <div class="container">

        <header>
          <h1>Title</h1>
        </header>

        <main>
          <p>Content with proper indentation</p>
        </main>

      </div>
      """

      assert template |> parse_template!() |> Map.get(:nodes) |> encode_nodes() == template
    end
  end

  describe "parse_template/1 error handling" do
    test "raises on unclosed tags" do
      assert_raise ArgumentError, "Missing closing tag for <div>", fn ->
        parse_template!("<div>Hello")
      end
    end

    test "raises on mismatched tags" do
      assert_raise ArgumentError, "Mismatched closing tag: expected </div>, got </span>", fn ->
        parse_template!("<div>Hello</span>")
      end
    end

    test "raises on unclosed expressions" do
      assert_raise ArgumentError, "Unclosed HEEx expression", fn ->
        parse_template!("Hello {name")
      end
    end

    test "raises on unclosed EEx expressions" do
      assert_raise ArgumentError, "Unclosed EEx expression", fn ->
        parse_template!("Hello <%= name")
      end
    end
  end

  describe "edge cases" do
    test "parses malformed HTML gracefully" do
      assert parse_template!("<div>Content</div>Some text").nodes |> length() == 2
    end

    test "normalizes element and attribute case" do
      %AST{nodes: nodes} =
        ~S(<INPut DISabled Checked="CHECKED" readONLY="" />) |> parse_template!()

      assert nodes == [
               {:element, "input", [{"disabled", true}, {"checked", true}, {"readonly", true}],
                []}
             ]

      assert encode_nodes(nodes) == "<input disabled checked readonly />"
    end

    test "parses boolean attributes" do
      %AST{nodes: nodes} =
        ~S(<input disabled checked="CHECKED" readonly="" />) |> parse_template!()

      assert nodes == [
               {:element, "input", [{"disabled", true}, {"checked", true}, {"readonly", true}],
                []}
             ]

      assert encode_nodes(nodes) == "<input disabled checked readonly />"
    end

    test "normalizes false booleans" do
      assert encode_node(
               {:element, "input", [{"disabled", false}, {"readonly", nil}, {"checked", true}],
                []}
             ) ==
               "<input checked />"
    end

    test "parses special characters in text" do
      %AST{nodes: [element]} =
        "<div>Content with &amp; special chars here</div>" |> parse_template!()

      assert {:element, "div", [], [{:text, "Content with &amp; special chars here"}]} = element
    end

    test "parses mixed quote styles in attributes" do
      %AST{nodes: [element]} =
        ~S(<div class='single' id="double">Content</div>) |> parse_template!()

      assert {:element, "div", [{"class", "single"}, {"id", "double"}], [{:text, "Content"}]} =
               element
    end

    test "parses empty templates" do
      assert "" |> parse_template!() |> Map.get(:nodes) |> encode_nodes() == ""
    end
  end
end
