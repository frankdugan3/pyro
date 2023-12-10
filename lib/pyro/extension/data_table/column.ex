if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Resource.DataTable.Column do
    @moduledoc """
    The configuration of a data table column in the `Pyro.Resource` extension.
    """
    defstruct [
      :name,
      :type,
      :label,
      :description,
      :path,
      :class
    ]

    @type t :: %__MODULE__{}
    @schema [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the column."
      ],
      type: [
        type: {:in, [:default]},
        required: false,
        doc: "The type of the the column.",
        default: :default
      ],
      label: [
        type: :string,
        required: false,
        doc: "The label of the column (defaults to capitalized name)."
      ],
      description: [
        type: :string,
        required: false,
        doc: "Override the default extracted description."
      ],
      class: [
        type: :string,
        required: false,
        doc: "Merge/override the default class."
      ],
      path: [
        type: {:list, :atom},
        required: false,
        doc: "Append to the root path (nested paths are appended)."
      ]
    ]

    @doc false
    def schema, do: @schema
  end
end
