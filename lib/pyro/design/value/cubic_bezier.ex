defmodule Pyro.Design.Value.CubicBezier do
  @moduledoc false

  @spec parse(any()) :: {:ok, {float(), float(), float(), float()}} | {:error, String.t()}
  def parse({p1x, p1y, p2x, p2y}), do: parse([p1x, p1y, p2x, p2y])

  def parse([p1x, p1y, p2x, p2y])
      when is_number(p1x) and is_number(p1y) and is_number(p2x) and is_number(p2y) do
    cond do
      p1x < 0 or p1x > 1 -> {:error, "cubic_bezier P1x must be in [0, 1], got #{p1x}"}
      p2x < 0 or p2x > 1 -> {:error, "cubic_bezier P2x must be in [0, 1], got #{p2x}"}
      true -> {:ok, {p1x / 1, p1y / 1, p2x / 1, p2y / 1}}
    end
  end

  def parse(other),
    do: {:error, "cubic_bezier expects 4 numbers as a tuple or list, got #{inspect(other)}"}

  @spec parse!(any()) :: {float(), float(), float(), float()}
  def parse!(input) do
    case parse(input) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "invalid cubic_bezier: #{reason}"
    end
  end
end
