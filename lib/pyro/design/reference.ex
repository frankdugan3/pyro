defmodule Pyro.Design.Reference do
  @moduledoc """
  A parsed DTCG reference.

  Stored on tokens (`$ref`) and groups (`$extends`). Dereferencing is a
  resolver concern — the DSL only guarantees a well-formed pointer that
  points at some existing path in the local design at compile time.

  ## Forms

    - JSON Pointer (RFC 6901): `"#/color/brand/500"`
    - Curly-brace alias: `"{color.brand.500}"`

  Both lower to the same internal segment list (`[:color, :brand, :"500"]`).
  Segments beginning with `$` (e.g. `:"$value"`, `:"$root"`) are preserved
  as-is; those are the DTCG reserved child names.
  """

  defstruct [:pointer, :kind]

  @type kind :: :pointer | :alias
  @type t :: %__MODULE__{pointer: [atom()], kind: kind()}

  @doc """
  Parses a reference. Returns an existing `%Reference{}` unchanged.

  Raises `ArgumentError` on malformed input.
  """
  @spec parse!(t() | String.t()) :: t()
  def parse!(%__MODULE__{} = ref), do: ref

  def parse!(string) when is_binary(string) do
    case parse(string) do
      {:ok, ref} -> ref
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  def parse!(other) do
    raise ArgumentError,
          "reference must be a string (`\"#/...\"` or `\"{...}\"`) or %Pyro.Design.Reference{}, got: #{inspect(other)}"
  end

  @doc """
  Parses a reference string without raising.
  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, String.t()}
  def parse("#/" <> rest) when rest != "" do
    with {:ok, segments} <- split_segments(rest, "/") do
      {:ok, %__MODULE__{pointer: segments, kind: :pointer}}
    end
  end

  def parse("{" <> body = raw) do
    case String.split(body, "}", parts: 2) do
      [inner, ""] when inner != "" ->
        with {:ok, segments} <- split_segments(inner, ".") do
          {:ok, %__MODULE__{pointer: segments, kind: :alias}}
        end

      _ ->
        {:error,
         "malformed alias reference #{inspect(raw)} — expected `{name.path}` with balanced braces"}
    end
  end

  def parse(other) when is_binary(other) do
    {:error,
     "reference #{inspect(other)} must be a JSON Pointer (`#/...`) or curly alias (`{...}`)"}
  end

  def parse(other) do
    {:error, "reference must be a string, got: #{inspect(other)}"}
  end

  @doc "Renders a reference back to its authored string form."
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{pointer: segments, kind: :pointer}),
    do: "#/" <> Enum.map_join(segments, "/", &Atom.to_string/1)

  def to_string(%__MODULE__{pointer: segments, kind: :alias}),
    do: "{" <> Enum.map_join(segments, ".", &Atom.to_string/1) <> "}"

  defp split_segments(str, separator) do
    segments = String.split(str, separator)

    if Enum.any?(segments, &(&1 == "")) do
      {:error, "reference contains empty segment: #{inspect(str)}"}
    else
      {:ok, Enum.map(segments, &String.to_atom/1)}
    end
  end
end
