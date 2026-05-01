defmodule Pyro.Design.Value.Shadow do
  @moduledoc false

  alias Pyro.Design.Value.{Color, Dimension}

  @required [:color, :offset_x, :offset_y, :blur, :spread]

  @spec parse(keyword()) :: {:ok, map()} | {:error, String.t()}
  def parse(kw) when is_list(kw) do
    with true <- Keyword.keyword?(kw),
         :ok <- ensure_keys(kw, @required),
         {:ok, color} <- Color.parse(Keyword.fetch!(kw, :color)),
         {:ok, ox} <- Dimension.parse(Keyword.fetch!(kw, :offset_x)),
         {:ok, oy} <- Dimension.parse(Keyword.fetch!(kw, :offset_y)),
         {:ok, blur} <- Dimension.parse(Keyword.fetch!(kw, :blur)),
         {:ok, spread} <- Dimension.parse(Keyword.fetch!(kw, :spread)) do
      {:ok, %{color: color, offset_x: ox, offset_y: oy, blur: blur, spread: spread}}
    else
      false -> {:error, "shadow expects a keyword list with #{inspect(@required)}"}
      {:error, reason} -> {:error, "shadow sub-value invalid: #{reason}"}
    end
  end

  def parse(other), do: {:error, "shadow expects a keyword list, got #{inspect(other)}"}

  @spec parse!(any()) :: map()
  def parse!(input) do
    case parse(input) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "invalid shadow: #{reason}"
    end
  end

  defp ensure_keys(kw, keys) do
    missing = Enum.reject(keys, &Keyword.has_key?(kw, &1))
    if missing == [], do: :ok, else: {:error, "missing required keys #{inspect(missing)}"}
  end
end
