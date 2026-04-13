defmodule Pyro.Sigils do
  @moduledoc false

  defmacro sigil_SVG({:<<>>, _meta, [string]}, _modifiers) when is_binary(string) do
    string
  end

  defmacro sigil_JS({:<<>>, _meta, [string]}, _modifiers) when is_binary(string) do
    string
  end
end
