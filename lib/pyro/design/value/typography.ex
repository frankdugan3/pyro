defmodule Pyro.Design.Value.Typography do
  @moduledoc false

  alias Pyro.Design.Value.{Dimension, FontFamily, FontWeight}

  @required [:font_family, :font_size, :font_weight]

  @spec parse(keyword()) :: {:ok, map()} | {:error, String.t()}
  def parse(kw) when is_list(kw) do
    with true <- Keyword.keyword?(kw),
         :ok <- ensure_keys(kw, @required),
         {:ok, family} <- FontFamily.parse(Keyword.fetch!(kw, :font_family)),
         {:ok, size} <- Dimension.parse(Keyword.fetch!(kw, :font_size)),
         {:ok, weight} <- FontWeight.parse(Keyword.fetch!(kw, :font_weight)),
         {:ok, line_height} <- parse_optional_number(Keyword.get(kw, :line_height)),
         {:ok, letter_spacing} <- parse_optional_dimension(Keyword.get(kw, :letter_spacing)) do
      base = %{font_family: family, font_size: size, font_weight: weight}

      value =
        base
        |> maybe_put(:line_height, line_height)
        |> maybe_put(:letter_spacing, letter_spacing)

      {:ok, value}
    else
      false -> {:error, "typography expects a keyword list with #{inspect(@required)}"}
      {:error, reason} -> {:error, "typography sub-value invalid: #{reason}"}
    end
  end

  def parse(other), do: {:error, "typography expects a keyword list, got #{inspect(other)}"}

  @spec parse!(any()) :: map()
  def parse!(input) do
    case parse(input) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "invalid typography: #{reason}"
    end
  end

  defp ensure_keys(kw, keys) do
    missing = Enum.reject(keys, &Keyword.has_key?(kw, &1))
    if missing == [], do: :ok, else: {:error, "missing required keys #{inspect(missing)}"}
  end

  defp parse_optional_number(nil), do: {:ok, nil}
  defp parse_optional_number(n) when is_number(n), do: {:ok, n / 1}

  defp parse_optional_number(other),
    do: {:error, "line_height must be a number, got #{inspect(other)}"}

  defp parse_optional_dimension(nil), do: {:ok, nil}
  defp parse_optional_dimension(input), do: Dimension.parse(input)

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
