defmodule Pyro.Design.Value.FontFamily do
  @moduledoc false

  @spec parse(any()) :: {:ok, String.t() | [String.t()]} | {:error, String.t()}
  def parse(value) when is_binary(value), do: {:ok, value}

  def parse(value) when is_list(value) do
    if Enum.all?(value, &is_binary/1) do
      {:ok, value}
    else
      {:error, "font_family list must contain only strings, got #{inspect(value)}"}
    end
  end

  def parse(other),
    do: {:error, "font_family expects a string or list of strings, got #{inspect(other)}"}

  @spec parse!(any()) :: String.t() | [String.t()]
  def parse!(input) do
    case parse(input) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "invalid font_family: #{reason}"
    end
  end
end
