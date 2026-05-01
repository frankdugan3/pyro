defmodule Pyro.Design.Value.FontWeight do
  @moduledoc false

  alias Pyro.Design.Value

  @spec parse(any()) :: {:ok, integer()} | {:error, String.t()}
  def parse(n) when is_integer(n) and n >= 1 and n <= 1000, do: {:ok, n}

  def parse(atom) when is_atom(atom) do
    case Map.fetch(Value.font_weight_aliases(), atom) do
      {:ok, n} ->
        {:ok, n}

      :error ->
        {:error,
         "font_weight alias #{inspect(atom)} unknown. Known: #{inspect(Map.keys(Value.font_weight_aliases()))}"}
    end
  end

  def parse(other),
    do:
      {:error,
       "font_weight must be an integer 1..1000 or a known alias atom, got #{inspect(other)}"}

  @spec parse!(any()) :: integer()
  def parse!(input) do
    case parse(input) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "invalid font_weight: #{reason}"
    end
  end
end
