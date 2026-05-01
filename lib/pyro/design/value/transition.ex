defmodule Pyro.Design.Value.Transition do
  @moduledoc false

  alias Pyro.Design.Value.{CubicBezier, Duration}

  @spec parse(keyword()) :: {:ok, map()} | {:error, String.t()}
  def parse(kw) when is_list(kw) do
    with true <- Keyword.keyword?(kw),
         :ok <- ensure_keys(kw, [:duration, :delay, :timing_function]),
         {:ok, duration} <- Duration.parse(Keyword.fetch!(kw, :duration)),
         {:ok, delay} <- Duration.parse(Keyword.fetch!(kw, :delay)),
         {:ok, timing} <- CubicBezier.parse(Keyword.fetch!(kw, :timing_function)) do
      {:ok, %{duration: duration, delay: delay, timing_function: timing}}
    else
      false ->
        {:error, "transition expects a keyword list with :duration, :delay, :timing_function"}

      {:error, reason} ->
        {:error, "transition sub-value invalid: #{reason}"}
    end
  end

  def parse(other), do: {:error, "transition expects a keyword list, got #{inspect(other)}"}

  @spec parse!(any()) :: map()
  def parse!(input) do
    case parse(input) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "invalid transition: #{reason}"
    end
  end

  defp ensure_keys(kw, keys) do
    missing = Enum.reject(keys, &Keyword.has_key?(kw, &1))
    if missing == [], do: :ok, else: {:error, "missing required keys #{inspect(missing)}"}
  end
end
