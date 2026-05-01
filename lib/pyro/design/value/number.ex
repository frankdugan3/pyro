defmodule Pyro.Design.Value.Number do
  @moduledoc false

  @spec parse(any()) :: {:ok, float()} | {:error, String.t()}
  def parse(n) when is_number(n), do: {:ok, n / 1}
  def parse(other), do: {:error, "number expects a number, got #{inspect(other)}"}

  @spec parse!(any()) :: float()
  def parse!(input) do
    case parse(input) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "invalid number: #{reason}"
    end
  end
end
