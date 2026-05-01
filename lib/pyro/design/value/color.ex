defmodule Pyro.Design.Value.Color do
  @moduledoc false

  # DTCG-compliant color parser. Accepts only strings (routed through
  # `Color.CSS.parse/1`) and `Color.t()` structs in one of the 14
  # DTCG-supported spaces. Other inputs are rejected.

  @dtcg_spaces ~w[srgb srgb_linear hsl hwb lab lch oklab oklch display_p3 a98_rgb prophoto_rgb
                  rec2020 xyz_d65 xyz_d50]a

  @doc "Returns the 14 DTCG `colorSpace` atoms."
  @spec dtcg_color_spaces() :: [atom()]
  def dtcg_color_spaces, do: @dtcg_spaces

  @doc """
  Parses a color input. Accepts a CSS string (via `Color.CSS.parse/1`)
  or a `Color.t()` struct in a DTCG-supported space.
  """
  @spec parse(any()) :: {:ok, Color.t()} | {:error, String.t()}
  def parse(%struct{} = color)
      when struct in [
             Color.SRGB,
             Color.RGB,
             Color.HSL,
             Color.Lab,
             Color.LCHab,
             Color.Oklab,
             Color.Oklch,
             Color.AdobeRGB,
             Color.XYZ
           ] do
    validate_struct(color)
  end

  def parse(%struct{}) do
    {:error,
     "color struct #{inspect(struct)} is not in a DTCG color space. " <>
       "Allowed DTCG spaces: #{inspect(@dtcg_spaces)} (represented by Color.SRGB / RGB / " <>
       "HSL / Lab / LCHab / Oklab / Oklch / AdobeRGB / XYZ)"}
  end

  def parse(input) when is_binary(input) do
    case Color.CSS.parse(input) do
      {:ok, %_{} = color} -> validate_struct(color)
      {:error, %_{} = ex} -> {:error, Exception.message(ex)}
      {:error, reason} -> {:error, to_string(reason)}
    end
  end

  def parse(other) do
    {:error, "color must be a CSS string or a Color.t() struct, got #{inspect(other)}"}
  end

  @doc "Like `parse/1` but raises `ArgumentError` on failure."
  @spec parse!(any()) :: Color.t()
  def parse!(input) do
    case parse(input) do
      {:ok, color} -> color
      {:error, reason} -> raise ArgumentError, "invalid color: #{reason}"
    end
  end

  defp validate_struct(%Color.SRGB{} = c), do: validate_channels(c, [:r, :g, :b])
  defp validate_struct(%Color.HSL{} = c), do: validate_channels(c, [:h, :s, :l])
  defp validate_struct(%Color.Lab{} = c), do: validate_channels(c, [:l, :a, :b])
  defp validate_struct(%Color.LCHab{} = c), do: validate_channels(c, [:l, :c, :h])
  defp validate_struct(%Color.Oklab{} = c), do: validate_channels(c, [:l, :a, :b])
  defp validate_struct(%Color.Oklch{} = c), do: validate_channels(c, [:l, :c, :h])
  defp validate_struct(%Color.AdobeRGB{} = c), do: validate_channels(c, [:r, :g, :b])

  defp validate_struct(%Color.XYZ{illuminant: ill} = c) when ill in [:D50, :D65],
    do: validate_channels(c, [:x, :y, :z])

  defp validate_struct(%Color.XYZ{illuminant: ill}) do
    {:error,
     "Color.XYZ illuminant #{inspect(ill)} is not DTCG-compatible. Use :D50 (xyz-d50) or " <>
       ":D65 (xyz-d65)"}
  end

  defp validate_struct(%Color.RGB{working_space: ws} = c)
       when ws in [:SRGB, :P3_D65, :Adobe, :ProPhoto, :Rec2020],
       do: validate_channels(c, [:r, :g, :b])

  defp validate_struct(%Color.RGB{working_space: ws}) do
    {:error,
     "Color.RGB working_space #{inspect(ws)} is not DTCG-compatible. Use :SRGB, :P3_D65, " <>
       ":Adobe, :ProPhoto, or :Rec2020"}
  end

  defp validate_channels(color, keys) do
    Enum.reduce_while(keys, {:ok, color}, fn key, acc ->
      case Map.get(color, key) do
        nil -> {:cont, acc}
        value when is_number(value) -> {:cont, acc}
        value -> {:halt, {:error, "component #{key} = #{inspect(value)} is invalid"}}
      end
    end)
  end
end
