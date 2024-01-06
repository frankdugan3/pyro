if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.DataTable.ActionType do
    @moduledoc """
    A data table for action(s) of a given type in the `Pyro.Ash.Extensions.Resource` extension.
    """
    use Pyro.Ash.Extensions.Resource.Schema

    @type t :: %__MODULE__{
            class: binary() | fun(),
            columns: [Pyro.Ash.Extensions.Resource.DataTable.Column],
            default_display: [atom()],
            default_sort: Pyro.Ash.Extensions.Resource.Schema.sort(),
            exclude: [atom()],
            name: atom()
          }
    defstruct [
      :class,
      :columns,
      :default_display,
      :default_sort,
      :exclude,
      :name
    ]

    @action_types {:one_of, [:read]}

    @schema [
      class: [
        type: css_class_schema_type(),
        required: false,
        doc: "Customize data table classes."
      ],
      default_display: [
        required: false,
        type: {:list, :atom},
        doc: "The columns to display by default.",
        default: []
      ],
      default_sort: [
        required: false,
        type: sort_schema_type(),
        doc: "The columns to sort on by default.",
        default: nil
      ],
      exclude: [
        required: false,
        type: {:list, :atom},
        doc: "The fields to exclude from columns.",
        default: []
      ],
      exclude: [
        required: false,
        type: {:list, :atom},
        doc: "The fields to exclude from columns.",
        default: []
      ],
      name: [
        type: {:or, [@action_types, {:list, @action_types}]},
        required: true,
        doc: "The action type(s) for this data table."
      ]
    ]

    @doc false
    def schema, do: @schema
  end
end
