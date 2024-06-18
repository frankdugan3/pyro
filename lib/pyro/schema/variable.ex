defmodule Pyro.Schema.Variable do
  @moduledoc false

  @schema [
    type: {:map, :atom, :any},
    default: %{},
    doc: "variables to merge into scope"
  ]
  @doc false
  def schema, do: @schema
end
