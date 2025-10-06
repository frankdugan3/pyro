defmodule Pyro.Test.Support.Helpers do
  @moduledoc false
  import Pyro.HEEx.AST

  defmacro sigil_H({:<<>>, meta, [expr]}, modifiers)
           when modifiers == [] or modifiers == ~c"noformat" do
    options = [
      file: __CALLER__.file,
      line: __CALLER__.line + 1,
      caller: __CALLER__,
      indentation: meta[:indentation] || 0
    ]

    expr
    |> parse!(options)
    |> Macro.escape()
  end
end
