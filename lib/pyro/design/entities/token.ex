defmodule Pyro.Design.Token do
  @moduledoc false

  alias Pyro.Design.Reference

  @types ~w[color dimension font_family font_weight duration cubic_bezier number
            stroke_style border transition shadow gradient typography]a

  @doc "The 13 DTCG `$type` atoms supported by the DSL."
  @spec types() :: [atom()]
  def types, do: @types

  use Pyro.Dsl.Entity,
    name: :token,
    args: [:name],
    describe: """
    Generic DTCG token escape hatch.

    Prefer the typed authoring macros in `Pyro.Design.Macros` (`color`,
    `dimension`, `shadow`, `typography`, `ref`, `root`, …) when writing
    a design. They parse and validate inputs at compile time. This generic `token` entity is for programmatically-built
    tokens, pre-parsed values, and `$ref`-only tokens that bypass
    per-type schemas.

    Every DTCG token in a compiled design is a `%Pyro.Design.Token{}`,
    regardless of whether it was authored via a typed macro or the
    generic entity.
    """,
    examples: [
      ~s|token :primary_action, ref: "#/color/brand/500"|,
      ~s|token :custom, type: :color, value: %Color.Oklch{l: 0.7, c: 0.2, h: 250}|
    ],
    transform: {__MODULE__, :transform_entity, []},
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "Token name. Becomes the DTCG object key under its group."
      ],
      type: [
        type: {:one_of, @types},
        doc: "DTCG `$type`. Inherited from nearest ancestor group if omitted."
      ],
      value: [type: :any, doc: "Parsed `$value`. Mutually exclusive with `:ref`."],
      ref: [
        type: :any,
        doc:
          "`$ref` pointer (string or `%Pyro.Design.Reference{}`). Mutually exclusive with `:value`."
      ],
      description: [type: :string, doc: "DTCG `$description`."],
      deprecated: [
        type: {:or, [:boolean, :string]},
        default: false,
        doc: "DTCG `$deprecated`. `true`, `false`, or an explanation string."
      ],
      extensions: [
        type: {:map, :string, :any},
        default: %{},
        doc: "DTCG `$extensions` map keyed by reverse-domain vendor ids."
      ],
      root?: [
        type: :boolean,
        default: false,
        doc: "True when this token is the DTCG `$root` child of its group."
      ]
    ]

  @doc false
  def transform_entity(%__MODULE__{ref: nil} = token), do: {:ok, token}
  def transform_entity(%__MODULE__{ref: %Reference{}} = token), do: {:ok, token}

  def transform_entity(%__MODULE__{ref: raw} = token) when is_binary(raw) do
    case Reference.parse(raw) do
      {:ok, ref} -> {:ok, %{token | ref: ref}}
      {:error, reason} -> {:error, reason}
    end
  end

  def transform_entity(%__MODULE__{ref: other}) do
    {:error, "token :ref must be a string or %Pyro.Design.Reference{}, got #{inspect(other)}"}
  end

  @doc """
  Builds a canonical `%Pyro.Design.Token{}` from a per-entity transient
  struct. Each typed entity's `transform/1` callback uses this to
  produce a Token from its build-time fields plus a parsed `$value`.

  `overrides` may include `:name`, `:ref`, or `:root?` (used by the
  `root` entity to set the reserved name and flag).
  """
  @spec from_spec(struct(), atom(), any(), map()) :: t()
  def from_spec(spec, type, value, overrides \\ %{}) do
    %__MODULE__{
      name: resolve(overrides, :name, spec),
      type: type,
      value: value,
      ref: Map.get(overrides, :ref),
      description: Map.get(spec, :description),
      deprecated: Map.get(spec, :deprecated, false),
      extensions: Map.get(spec, :extensions, %{}),
      root?: Map.get(overrides, :root?, false)
    }
  end

  defp resolve(overrides, key, spec) do
    case Map.fetch(overrides, key) do
      {:ok, value} -> value
      :error -> Map.get(spec, key)
    end
  end
end
