if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.DataTable.ActionType do
    @moduledoc """
    A data table for action(s) of a given type in the `Pyro.Ash.Extensions.Resource` extension.
    """
    use Pyro.Ash.Extensions.Resource.Schema

    @type t :: %__MODULE__{}
    defstruct [:name, :class, :exclude, :columns]

    @action_types {:one_of, [:read]}

    @schema [
      name: [
        type: {:or, [@action_types, {:list, @action_types}]},
        required: true,
        doc: "The action type(s) for this data table."
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
