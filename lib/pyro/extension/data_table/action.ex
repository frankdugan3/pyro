if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Resource.DataTable.Action do
    @moduledoc """
    A data table for action(s) in the `Pyro.Resource` extension.
    """

    @type t :: %__MODULE__{}
    defstruct [:name, :label, :description, :class, :exclude, :columns]

    @schema [
      name: [
        type: {:or, [:atom, {:list, :atom}]},
        required: true,
        doc: "The action name(s) for this data table."
      ],
      label: [
        type: :string,
        required: false,
        doc: "The label for this data table (defaults to capitalized name)."
      ],
      description: [
        type: :string,
        required: false,
        doc: "The description for this data table (defaults to action's description)."
      ],
      class: [
        type: :string,
        required: false,
        doc: "Customize data table classes."
      ],
      exclude: [
        required: false,
        type: {:list, :atom},
        doc: "The fields to exclude from columns.",
        default: []
      ]
    ]

    @doc false
    def schema, do: @schema
  end
end
