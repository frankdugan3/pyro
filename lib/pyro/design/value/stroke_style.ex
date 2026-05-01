defmodule Pyro.Design.Value.StrokeStyle do
  @moduledoc false

  alias Pyro.Design.Value.Dimension

  @string_styles ~w[solid dashed dotted double groove ridge outset inset]
  @line_caps ~w[round butt square]a

  @spec parse(any()) :: {:ok, String.t() | map()} | {:error, String.t()}
  def parse(value) when is_binary(value) do
    if value in @string_styles do
      {:ok, value}
    else
      {:error, "stroke_style string #{inspect(value)} must be one of #{inspect(@string_styles)}"}
    end
  end

  def parse(atom) when is_atom(atom) and atom not in [nil, true, false],
    do: parse(Atom.to_string(atom))

  def parse(kw) when is_list(kw) do
    if Keyword.keyword?(kw) do
      with {:ok, dash_array} <- parse_dash_array(Keyword.get(kw, :dash_array, [])),
           {:ok, line_cap} <- parse_line_cap(Keyword.get(kw, :line_cap, :butt)) do
        {:ok, %{dash_array: dash_array, line_cap: line_cap}}
      end
    else
      {:error,
       "stroke_style list must be a keyword list with :dash_array and :line_cap, got #{inspect(kw)}"}
    end
  end

  def parse(other),
    do: {:error, "stroke_style expects a string, atom, or keyword list, got #{inspect(other)}"}

  @spec parse!(any()) :: String.t() | map()
  def parse!(input) do
    case parse(input) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "invalid stroke_style: #{reason}"
    end
  end

  defp parse_dash_array(list) when is_list(list) do
    list
    |> Enum.reduce_while({:ok, []}, fn element, {:ok, acc} ->
      case Dimension.parse(element) do
        {:ok, dim} -> {:cont, {:ok, [dim | acc]}}
        {:error, reason} -> {:halt, {:error, "dash_array element invalid: #{reason}"}}
      end
    end)
    |> case do
      {:ok, acc} -> {:ok, Enum.reverse(acc)}
      err -> err
    end
  end

  defp parse_dash_array(other),
    do: {:error, "dash_array must be a list of dimensions, got #{inspect(other)}"}

  defp parse_line_cap(cap) when cap in @line_caps, do: {:ok, cap}

  defp parse_line_cap(other),
    do: {:error, "line_cap must be one of #{inspect(@line_caps)}, got #{inspect(other)}"}
end
