defmodule Pyro.Design.Value.Dimension do
  @moduledoc false

  @units [:px, :rem]

  @spec parse(any()) :: {:ok, {float(), atom()}} | {:error, String.t()}
  def parse({n, unit}) when is_number(n) and unit in @units, do: {:ok, {n / 1, unit}}

  def parse(other),
    do: {:error, "dimension expects {number, :px | :rem}, got #{inspect(other)}"}

  @spec parse!(any()) :: {float(), atom()}
  def parse!(input) do
    case parse(input) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "invalid dimension: #{reason}"
    end
  end
end
