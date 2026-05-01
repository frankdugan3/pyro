defmodule Pyro.Design.Value.Duration do
  @moduledoc false

  @units [:ms, :s]

  @spec parse(any()) :: {:ok, {float(), atom()}} | {:error, String.t()}
  def parse({n, unit}) when is_number(n) and unit in @units, do: {:ok, {n / 1, unit}}

  def parse(other),
    do: {:error, "duration expects {number, :ms | :s}, got #{inspect(other)}"}

  @spec parse!(any()) :: {float(), atom()}
  def parse!(input) do
    case parse(input) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "invalid duration: #{reason}"
    end
  end
end
