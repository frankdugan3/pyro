defmodule Pyro.HEExTest do
  use ExUnit.Case, async: true

  import Pyro.HEEx
  import Pyro.HEEx.AST
  import Pyro.Test.Support.Helpers

  alias Pyro.HEEx.AST.{Attribute, Element}

  doctest Pyro.HEEx, import: true

  describe "tally_attributes/2" do
    test "tallies specific attribute values" do
      tally =
        ~H"""
        <div pyro-component="button">
          <span pyro-component="icon">Content</span>
          <p pyro-component="button">More content</p>
        </div>
        """
        |> tally_attributes("pyro-component")

      assert tally == %{
               "pyro-component" => %{
                 "button" => 2,
                 "icon" => 1
               }
             }
    end

    test "tallies wildcard attribute patterns" do
      tally =
        """
        <div pyro-test="value1" pyro-other="value2">
          <span pyro-test="value3" regular-attr="ignored">Content</span>
          <p pyro-component="button" pyro-test="value1">More content</p>
        </div>
        """
        |> parse!()
        |> tally_attributes(~r/^pyro-/)

      assert tally == %{
               "pyro-component" => %{
                 "button" => 1
               },
               "pyro-other" => %{
                 "value2" => 1
               },
               "pyro-test" => %{
                 "value1" => 2,
                 "value3" => 1
               }
             }
    end

    test "tallies boolean attributes" do
      ast =
        """
        <input required disabled />
        <input required />
        <button disabled>Click me</button>
        """
        |> parse!()

      assert tally_attributes(ast, "required") == %{"required" => %{true => 2}}
      assert tally_attributes(ast, "disabled") == %{"disabled" => %{true => 2}}
    end

    test "tallies HEEx expressions in attribute values" do
      tally =
        """
        <div pyro-value={@dynamic_value}>
          <span pyro-value={@another_value}>Content</span>
          <p pyro-value="static">More content</p>
        </div>
        """
        |> parse!()
        |> tally_attributes("pyro-value")

      assert tally == %{
               "pyro-value" => %{
                 "@another_value" => 1,
                 "@dynamic_value" => 1,
                 "static" => 1
               }
             }
    end

    test "tallies mixed attribute types" do
      tally =
        """
        <div pyro-type="static" pyro-flag pyro-dynamic={@value}>
          <span pyro-type="static" pyro-other="test">Content</span>
        </div>
        """
        |> parse!()
        |> tally_attributes(~r/^pyro-/)

      assert tally == %{
               "pyro-dynamic" => %{"@value" => 1},
               "pyro-flag" => %{true => 1},
               "pyro-other" => %{"test" => 1},
               "pyro-type" => %{"static" => 2}
             }
    end

    test "tally is an empty map when no matching attributes found" do
      tally =
        """
        <div class="container">
          <span id="test">Content</span>
        </div>
        """
        |> parse!()
        |> tally_attributes("pyro-component")

      assert tally == %{}
    end

    test "tallies nested elements correctly" do
      tally =
        """
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
        |> parse!()
        |> tally_attributes("pyro-level")

      assert tally == %{
               "pyro-level" => %{
                 "1" => 1,
                 "2" => 2,
                 "3" => 2,
                 "4" => 1
               }
             }
    end

    test "tallies complex real-world template" do
      tally =
        """
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
        |> parse!()
        |> tally_attributes(~r/^pyro-/)

      assert tally == %{
               "pyro-action" => %{
                 "like" => 1,
                 "share" => 1
               },
               "pyro-component" => %{
                 "actions" => 1,
                 "post" => 1,
                 "post-body" => 1,
                 "post-header" => 1
               },
               "pyro-element" => %{
                 "content" => 1,
                 "timestamp" => 1,
                 "title" => 1
               },
               "pyro-enhanced" => %{
                 true => 2
               }
             }
    end
  end
end
