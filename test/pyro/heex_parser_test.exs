defmodule Pyro.HeexParserTest do
  use ExUnit.Case, async: true
  alias Pyro.HeexParser

  doctest Pyro.HeexParser, import: true

  describe "complex Heex" do
    test "round trip parse/encode AST" do
      template = """
      <!-- Note: This should stick around. -->
      <article>
        <header>
          <h1>{@post.title}</h1>
          <time><%=@post.created_at%></time>
        </header>
        <ul>
          {for post <- @posts do}
            <.card>
              <:header class="card-header">
                <.icon name="user" />
                <span><%= card.title %></span>
              </:header>
              <:body>
                <.post_preview
                  pyro-class="post-preview"
                  post={post} />
              </:body>
            </.card>
          {end}
        </ul>
        <section class="content">
          {@post.body}
        </section>
      </article>
      """

      assert {:ok, ast} = HeexParser.parse(template)

      assert [
               {:comment, " Note: This should stick around. "},
               {:text, "\n"},
               {
                 :element,
                 "article",
                 [],
                 [
                   {:text, "\n  "},
                   {
                     :element,
                     "header",
                     [],
                     [
                       {:text, "\n    "},
                       {
                         :element,
                         "h1",
                         [],
                         [heex_expr: "@post.title"]
                       },
                       {:text, "\n    "},
                       {
                         :element,
                         "time",
                         [],
                         [{:eex_expr, "=", "@post.created_at"}]
                       },
                       {:text, "\n  "}
                     ]
                   },
                   {:text, "\n  "},
                   {
                     :element,
                     "ul",
                     [],
                     [
                       {:text, "\n    "},
                       {:heex_expr, "for post <- @posts do"},
                       {:text, "\n      "},
                       {
                         :element,
                         ".card",
                         [],
                         [
                           {:text, "\n        "},
                           {:element, ":header", [{"class", "card-header", " "}],
                            [
                              {:text, "\n          "},
                              {:element, ".icon", [{"name", "user", " "}], []},
                              {:text, "\n          "},
                              {:element, "span", [], [{:eex_expr, "=", " card.title "}]},
                              {:text, "\n        "}
                            ]},
                           {:text, "\n        "},
                           {:element, ":body", [],
                            [
                              {:text, "\n          "},
                              {:element, ".post_preview",
                               [
                                 {"pyro-class", "post-preview", "\n            "},
                                 {"post", {:heex_expr, "post"}, "\n            "}
                               ], []},
                              {:text, "\n        "}
                            ]},
                           {:text, "\n      "}
                         ]
                       },
                       {:text, "\n    "},
                       {:heex_expr, "end"},
                       {:text, "\n  "}
                     ]
                   },
                   {:text, "\n  "},
                   {
                     :element,
                     "section",
                     [{"class", "content", " "}],
                     [
                       text: "\n    ",
                       heex_expr: "@post.body",
                       text: "\n  "
                     ]
                   },
                   {:text, "\n"}
                 ]
               },
               {:text, "\n"}
             ] = ast

      assert HeexParser.encode(ast) == template
    end
  end

  describe "parse/1 whitespace and comments" do
    test "preserves whitespace in templates" do
      template = """
      <div>
        <p>Hello World</p>
        <span>  Multiple spaces  </span>
      </div>
      """

      assert {:ok, ast} = HeexParser.parse(template)
      assert HeexParser.encode(ast) == template
    end

    test "preserves HTML comments" do
      template = """
      <!-- This is a comment -->
      <div>
        <!-- Another comment -->
        <p>Content</p>
      </div>
      """

      assert {:ok, ast} = HeexParser.parse(template)

      # Check that comments are preserved in AST
      assert Enum.any?(ast, fn
               {:comment, _} -> true
               _ -> false
             end)

      assert HeexParser.encode(ast) == template
    end

    test "preserves multiline comments" do
      template = """
      <!--
        This is a multiline comment
        with multiple lines
      -->
      <div>Content</div>
      """

      assert {:ok, ast} = HeexParser.parse(template)
      assert HeexParser.encode(ast) == template
    end

    test "handles comments with special characters" do
      template = """
      <!-- TODO: Add validation for email & phone -->
      <form>
        <!-- @deprecated: Use new input component -->
        <input type="text" />
      </form>
      """

      assert {:ok, ast} = HeexParser.parse(template)
      assert HeexParser.encode(ast) == template
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

      assert {:ok, ast} = HeexParser.parse(template)
      assert HeexParser.encode(ast) == template
    end
  end

  describe "parse/1 error handling" do
    test "returns error for unclosed tags" do
      assert {:error, msg} = HeexParser.parse("<div>Hello")
      assert msg =~ "Missing closing tag"
    end

    test "returns error for mismatched tags" do
      assert {:error, msg} = HeexParser.parse("<div>Hello</span>")
      assert msg =~ "Mismatched closing tag"
    end

    test "returns error for unclosed HEEx expressions" do
      assert {:error, msg} = HeexParser.parse("Hello {name")
      assert msg =~ "Unclosed HEEx expression"
    end

    test "returns error for unclosed EEx expressions" do
      assert {:error, msg} = HeexParser.parse("Hello <%= name")
      assert msg =~ "Unclosed EEx expression"
    end
  end

  describe "edge cases" do
    test "handles malformed HTML gracefully" do
      assert {:ok, ast} = HeexParser.parse("<div>Content</div>Some text")
      assert length(ast) == 2
    end

    test "handles boolean attributes" do
      template = "<input disabled />"
      assert {:ok, ast} = HeexParser.parse(template)
      assert ast == [{:element, "input", [{"disabled", "disabled", " "}], []}]
      assert HeexParser.encode(ast) == template

      template2 = "<input required checked />"
      assert {:ok, ast2} = HeexParser.parse(template2)

      assert ast2 == [
               {:element, "input", [{"required", "required", " "}, {"checked", "checked", ""}],
                []}
             ]

      assert HeexParser.encode(ast2) == template2

      template3 = "<input type=\"text\" required value=\"test\" />"
      assert {:ok, ast3} = HeexParser.parse(template3)

      assert ast3 == [
               {:element, "input",
                [{"type", "text", " "}, {"required", "required", " "}, {"value", "test", ""}], []}
             ]

      assert HeexParser.encode(ast3) == template3
    end

    test "handles special characters in text" do
      assert {:ok, ast} = HeexParser.parse("<div>Content with &amp; special chars here</div>")
      [element] = ast
      assert {:element, "div", [], [{:text, "Content with &amp; special chars here"}]} = element
    end

    test "handles mixed quote styles in attributes" do
      template = "<div class='single' id=\"double\">Content</div>"
      assert {:ok, ast} = HeexParser.parse(template)

      [element] = ast

      assert {:element, "div", [{"class", "single", " "}, {"id", "double", " "}],
              [{:text, "Content"}]} =
               element
    end

    test "handles empty templates" do
      template = ""
      assert {:ok, ast} = HeexParser.parse(template)
      assert ast == []
      assert HeexParser.encode(ast) == template
    end
  end

  describe "tally_attributes/2" do
    test "tallies specific attribute values" do
      template = """
      <div pyro-component="button">
        <span pyro-component="icon">Content</span>
        <p pyro-component="button">More content</p>
      </div>
      """

      {:ok, ast} = HeexParser.parse(template)
      result = HeexParser.tally_attributes(ast, "pyro-component")

      assert result == %{
               "pyro-component" => %{
                 "button" => 2,
                 "icon" => 1
               }
             }
    end

    test "tallies wildcard attribute patterns" do
      template = """
      <div pyro-test="value1" pyro-other="value2">
        <span pyro-test="value3" regular-attr="ignored">Content</span>
        <p pyro-component="button" pyro-test="value1">More content</p>
      </div>
      """

      {:ok, ast} = HeexParser.parse(template)
      result = HeexParser.tally_attributes(ast, "pyro-*")

      assert result == %{
               "pyro-test" => %{
                 "value1" => 2,
                 "value3" => 1
               },
               "pyro-other" => %{
                 "value2" => 1
               },
               "pyro-component" => %{
                 "button" => 1
               }
             }
    end

    test "handles boolean attributes" do
      template = """
      <input required disabled />
      <input required />
      <button disabled>Click me</button>
      """

      {:ok, ast} = HeexParser.parse(template)

      required_result = HeexParser.tally_attributes(ast, "required")
      assert required_result == %{"required" => %{true => 2}}

      disabled_result = HeexParser.tally_attributes(ast, "disabled")
      assert disabled_result == %{"disabled" => %{true => 2}}
    end

    test "handles HEEx expressions in attribute values" do
      template = """
      <div pyro-value={@dynamic_value}>
        <span pyro-value={@another_value}>Content</span>
        <p pyro-value="static">More content</p>
      </div>
      """

      {:ok, ast} = HeexParser.parse(template)
      result = HeexParser.tally_attributes(ast, "pyro-value")

      assert result == %{
               "pyro-value" => %{
                 "@dynamic_value" => 1,
                 "@another_value" => 1,
                 "static" => 1
               }
             }
    end

    test "handles mixed attribute types" do
      template = """
      <div pyro-type="static" pyro-flag pyro-dynamic={@value}>
        <span pyro-type="static" pyro-other="test">Content</span>
      </div>
      """

      {:ok, ast} = HeexParser.parse(template)
      result = HeexParser.tally_attributes(ast, "pyro-*")

      assert result == %{
               "pyro-type" => %{
                 "static" => 2
               },
               "pyro-flag" => %{
                 true => 1
               },
               "pyro-dynamic" => %{
                 "@value" => 1
               },
               "pyro-other" => %{
                 "test" => 1
               }
             }
    end

    test "returns empty map when no matching attributes found" do
      template = """
      <div class="container">
        <span id="test">Content</span>
      </div>
      """

      {:ok, ast} = HeexParser.parse(template)
      result = HeexParser.tally_attributes(ast, "pyro-component")

      assert result == %{}
    end

    test "handles nested elements correctly" do
      template = """
      <div pyro-level="1">
        <header pyro-level="2">
          <h1 pyro-level="3">Title</h1>
        </header>
        <main pyro-level="2">
          <section pyro-level="3">
            <p pyro-level="4">Content</p>
          </section>
        </main>
      </div>
      """

      {:ok, ast} = HeexParser.parse(template)
      result = HeexParser.tally_attributes(ast, "pyro-level")

      assert result == %{
               "pyro-level" => %{
                 "1" => 1,
                 "2" => 2,
                 "3" => 2,
                 "4" => 1
               }
             }
    end

    test "works with complex real-world template" do
      template = """
      <article pyro-component="post">
        <header pyro-component="post-header">
          <h1 pyro-element="title">{@post.title}</h1>
          <time pyro-element="timestamp"><%=@post.created_at%></time>
        </header>
        <section pyro-component="post-body" pyro-enhanced>
          <p pyro-element="content">{@post.body}</p>
          <div pyro-component="actions">
            <button pyro-action="like" pyro-enhanced>Like</button>
            <button pyro-action="share">Share</button>
          </div>
        </section>
      </article>
      """

      {:ok, ast} = HeexParser.parse(template)
      result = HeexParser.tally_attributes(ast, "pyro-*")

      expected = %{
        "pyro-component" => %{
          "post" => 1,
          "post-header" => 1,
          "post-body" => 1,
          "actions" => 1
        },
        "pyro-element" => %{
          "title" => 1,
          "timestamp" => 1,
          "content" => 1
        },
        "pyro-enhanced" => %{
          true => 2
        },
        "pyro-action" => %{
          "like" => 1,
          "share" => 1
        }
      }

      assert result == expected
    end
  end
end
