defmodule Pyro.Design.Value.Gradient do
  @moduledoc false

  alias Pyro.Design.Value.Color

  @spec parse([keyword()]) :: {:ok, [map()]} | {:error, String.t()}
  def parse(stops) when is_list(stops) and stops != [] do
    if Enum.all?(stops, &is_list/1) do
      reduce_stops(stops)
    else
      {:error, "gradient expects a list of stop keyword lists, got #{inspect(stops)}"}
    end
  end

  def parse([]), do: {:error, "gradient must have at least one stop"}

  def parse(other),
    do: {:error, "gradient expects a list of stop keyword lists, got #{inspect(other)}"}

  defp reduce_stops(stops) do
    stops
    |> Enum.reduce_while({:ok, []}, &accumulate_stop/2)
    |> case do
      {:ok, acc} -> {:ok, Enum.reverse(acc)}
      err -> err
    end
  end

  defp accumulate_stop(stop, {:ok, acc}) do
    case parse_stop(stop) do
      {:ok, value} -> {:cont, {:ok, [value | acc]}}
      {:error, reason} -> {:halt, {:error, "gradient stop invalid: #{reason}"}}
    end
  end

  @spec parse!(any()) :: [map()]
  def parse!(input) do
    case parse(input) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "invalid gradient: #{reason}"
    end
  end

  defp parse_stop(kw) when is_list(kw) do
    with true <- Keyword.keyword?(kw),
         {:ok, color_input} <- fetch_required(kw, :color),
         {:ok, position} <- fetch_required(kw, :position),
         {:ok, color} <- Color.parse(color_input),
         :ok <- validate_position(position) do
      {:ok, %{color: color, position: position / 1}}
    else
      false -> {:error, "stop must be a keyword list with :color and :position"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_stop(other), do: {:error, "stop must be a keyword list, got #{inspect(other)}"}

  defp fetch_required(kw, key) do
    case Keyword.fetch(kw, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, "missing required key :#{key}"}
    end
  end

  defp validate_position(p) when is_number(p) and p >= 0 and p <= 1, do: :ok

  defp validate_position(other),
    do: {:error, "position must be a number in [0.0, 1.0], got #{inspect(other)}"}
end
