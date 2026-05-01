defmodule Pyro.Design.Value.Border do
  @moduledoc false

  alias Pyro.Design.Value.{Color, Dimension, StrokeStyle}

  @spec parse(keyword()) :: {:ok, map()} | {:error, String.t()}
  def parse(kw) when is_list(kw) do
    with true <- Keyword.keyword?(kw),
         :ok <- ensure_keys(kw, [:color, :width, :style]),
         {:ok, color} <- Color.parse(Keyword.fetch!(kw, :color)),
         {:ok, width} <- Dimension.parse(Keyword.fetch!(kw, :width)),
         {:ok, style} <- StrokeStyle.parse(Keyword.fetch!(kw, :style)) do
      {:ok, %{color: color, width: width, style: style}}
    else
      false -> {:error, "border expects a keyword list with :color, :width, :style"}
      {:error, reason} -> {:error, "border sub-value invalid: #{reason}"}
    end
  end

  def parse(other), do: {:error, "border expects a keyword list, got #{inspect(other)}"}

  @spec parse!(any()) :: map()
  def parse!(input) do
    case parse(input) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "invalid border: #{reason}"
    end
  end

  defp ensure_keys(kw, keys) do
    missing = Enum.reject(keys, &Keyword.has_key?(kw, &1))
    if missing == [], do: :ok, else: {:error, "missing required keys #{inspect(missing)}"}
  end
end
