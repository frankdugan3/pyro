defmodule Pyro.Design.Group do
  @moduledoc false

  use Pyro.Dsl.Entity,
    name: :group,
    args: [:name],
    describe: """
    A DTCG group — a container of tokens and/or nested groups.

    Groups carry optional `$type` (inherited by descendants),
    `$description`, `$deprecated`, `$extensions`, and `$extends`.
    Inside a group block, the typed authoring macros from
    `Pyro.Design.Macros` (`color`, `dimension`, `shadow`, …) are
    available.
    """,
    recursive_as: :children,
    entities: [children: [Pyro.Design.Token]],
    imports: [Pyro.Design.Macros],
    transform: {__MODULE__, :transform_entity, []},
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "Group name. Becomes the DTCG object key at this level."
      ],
      type: [
        type: {:one_of, Pyro.Design.Token.types()},
        doc: "Default DTCG `$type` for descendants that don't set one explicitly."
      ],
      description: [
        type: :string,
        doc: "DTCG `$description`."
      ],
      deprecated: [
        type: {:or, [:boolean, :string]},
        default: false,
        doc: "DTCG `$deprecated`. `true`, `false`, or an explanation string."
      ],
      extends: [
        type: :any,
        doc: """
        DTCG `$extends` reference (a `%Pyro.Design.Reference{}` or
        string that parses into one). Validated at compile time;
        inheritance is a resolver concern.
        """
      ],
      extensions: [
        type: {:map, :string, :any},
        default: %{},
        doc: "DTCG `$extensions` map keyed by reverse-domain vendor ids."
      ]
    ]

  @doc false
  def transform_entity(%__MODULE__{extends: nil} = group), do: {:ok, group}
  def transform_entity(%__MODULE__{extends: %Pyro.Design.Reference{}} = group), do: {:ok, group}

  def transform_entity(%__MODULE__{extends: raw} = group) when is_binary(raw) do
    case Pyro.Design.Reference.parse(raw) do
      {:ok, ref} -> {:ok, %{group | extends: ref}}
      {:error, reason} -> {:error, reason}
    end
  end

  def transform_entity(%__MODULE__{extends: other}) do
    {:error, "group :extends must be a string or %Pyro.Design.Reference{}, got #{inspect(other)}"}
  end
end
