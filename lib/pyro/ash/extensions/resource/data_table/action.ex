if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.DataTable.Action do
    @moduledoc """
    A data table for action(s) in the `Pyro.Ash.Extensions.Resource` extension.
    """
    use Pyro.Ash.Extensions.Resource.Schema

    @type t :: %__MODULE__{}
    defstruct [:name, :label, :description, :class, :exclude, :columns]

    @schema [
      name: [
        type: {:wrap_list, :atom},
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
        type: css_class_type(),
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
