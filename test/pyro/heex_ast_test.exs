defmodule Pyro.HEEx.ASTTest do
  use ExUnit.Case, async: true

  import Pyro.HEEx.AST
  import Pyro.Test.Support.Helpers

  alias Pyro.HEEx.AST
  alias Pyro.HEEx.AST.Attribute
  alias Pyro.HEEx.AST.EExComment
  alias Pyro.HEEx.AST.Element
  alias Pyro.HEEx.AST.ParseError
  alias Pyro.HEEx.AST.Text

  doctest AST, import: true

  describe "parse_template/1" do
    test "preserves whitespace in templates" do
      ast = ~H"""
         <div>
           <p>Hello World</p>
        <span> Multiple spaces </span>
        <input />
      </div>
      """noformat

      assert ast.source == encode(ast)
    end

    test "preserves HTML and EEx comments with whitespace" do
      ast = ~H"""
      <!-- This is a single-line HTML comment -->
      <div phx-no-format>
        <!-- Another HTML comment...
          Multi-line!
               -->
           <%!--   A single-line EEx comment --%>
        <%!-- An EEx comment
             Multi-line!
          --%>
        <p>Content</p>
      </div>
      """

      assert [
               %AST.HTMLComment{
                 content: " This is a single-line HTML comment "
               },
               %AST.Element{
                 attributes: [%AST.Attribute{name: "phx-no-format", value: true}],
                 children: [
                   %AST.HTMLComment{
                     content: " Another HTML comment...\n    Multi-line!\n         "
                   },
                   %EExComment{content: "   A single-line EEx comment "},
                   %Text{content: ""},
                   %EExComment{content: " An EEx comment\n       Multi-line!\n    "},
                   %Text{content: ""},
                   %Element{attributes: [], children: [%Text{content: "Content"}], tag: "p"},
                   %Text{content: ""}
                 ],
                 tag: "div"
               },
               %AST.Text{content: "", post: "", pre: "\n"}
             ] = ast.nodes

      assert ast.source == encode(ast)
    end

    test "parses/encodes complex template" do
      ast = ~H"""
      <div>
        <!-- Note: This should stick around. -->
        <article>
          <header>
            <h1>{@post.title}</h1>
            <time>{@post.created_at}</time>
          </header>
          <%= for i <- 0..10 do %>
            <span>{i}</span>
          <% end %>
          <ul>
                <% # nothing %>
            <.card :for={post <- @posts}>
              <:header class="card-header">
                <.icon name="user" />
                <span><%= card.title %></span>
              </:header>
              <:body>
                <.post_preview pyro-class="post-preview" post={post} />
              </:body>
            </.card>
          </ul>
          <section class="content">
            {@post.body}
          </section>
        </article>
        <.simple_form :let={f} form={@form}>
          <.input field={f[:name]} label="Name" />
          <input type="hidden" value="invisible" />
          <ul>
            <li :for={term <- @terms}>{term.humanized}</li>
          </ul>
        </.simple_form>
      </div>
      """noformat

      assert ast.source == encode(ast)
    end
  end

  describe "format errors" do
    # From EEx tokenizer
    assert_raise ParseError,
                 """
                 nofile:108:13: expected closing '%>' for EEx expression
                     |
                 105 |                 <time>{@post.created_at}</time>
                 106 |               </header>
                 107 |             </article>
                 108 |             <%= if true do >
                     |             ^\
                 """,
                 fn ->
                   AST.parse!(
                     """
                     <div>
                       <article>
                         <header>
                           <h1>{@post.title}</h1>
                           <time>{@post.created_at}</time>
                         </header>
                       </article>
                       <%= if true do >
                     </div>
                     """,
                     source_offset: 100,
                     line: 101,
                     indentation: 10
                   )
                 end

    # From Phoenix LiveView Tokenizer
    assert_raise ParseError,
                 """
                 nofile:108:13: expected closing `-->` for comment
                     |
                 105 |                 <time>{@post.created_at}</time>
                 106 |               </header>
                 107 |             </article>
                 108 |             <!-->
                     |             ^\
                 """,
                 fn ->
                   AST.parse!(
                     """
                     <div>
                       <article>
                         <header>
                           <h1>{@post.title}</h1>
                           <time>{@post.created_at}</time>
                         </header>
                       </article>
                       <!-->
                     </div>
                     """,
                     source_offset: 100,
                     line: 101,
                     indentation: 10
                   )
                 end

    # From Pyro.HEEx.AST
    assert_raise ParseError,
                 """
                 nofile:108:13: expected closing tag </span>
                     |
                 105 |                 <time>{@post.created_at}</time>
                 106 |               </header>
                 107 |             </article>
                 108 |             <span>
                     |             ^\
                 """,
                 fn ->
                   AST.parse!(
                     """
                     <div>
                       <article>
                         <header>
                           <h1>{@post.title}</h1>
                           <time>{@post.created_at}</time>
                         </header>
                       </article>
                       <span>
                     </div>
                     """,
                     source_offset: 100,
                     line: 101,
                     indentation: 10
                   )
                 end
  end

  describe "edge cases" do
    test "normalizes boolean attributes" do
      ast = ~H"""
      <input type="checkbox" disabled readonly="readONLY" checked="" />
      """

      assert [
               %Element{
                 attributes: [
                   %Attribute{name: "type", value: "checkbox"},
                   %Attribute{name: "disabled", value: true},
                   %Attribute{name: "readonly", value: true},
                   %Attribute{name: "checked", value: true}
                 ],
                 self_closing?: true,
                 tag: "input"
               },
               %Text{content: ""}
             ] = ast.nodes

      assert """
             <input type="checkbox" disabled readonly checked />
             """ == encode(ast)

      assert encode(%AST{
               nodes: [
                 %Element{
                   attributes: [%Attribute{name: "disabled", type: :boolean, value: false}],
                   self_closing?: true,
                   tag: "input"
                 }
               ]
             }) == "<input />"
    end

    test "trims attribute whitespace" do
      ast = ~H"""
      <input       type="button"        disabled />
      """noformat

      assert """
             <input type="button" disabled />
             """ == encode(ast)
    end

    test "attribute name normalized" do
      ast = ~H"""
      <input type="button" DIsABlED />
      """noformat

      assert """
             <input type="button" disabled />
             """ == encode(ast)
    end

    test "element name normalized" do
      ast = ~H"""
      <inPuT type="button" disabled />
      <dIV></diV>
      """noformat

      assert """
             <input type="button" disabled />
             <div></div>
             """ == encode(ast)
    end

    test "parses malformed HTML gracefully" do
      ast = ~H"<div>Content</div>Some text"
      assert length(ast.nodes) == 2
      assert ast.source == encode(ast)
    end

    test "parses empty templates" do
      assert encode(~H"") == ""
    end
  end
end
