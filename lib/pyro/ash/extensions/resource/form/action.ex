if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Form.Action do
    @moduledoc """
    A form for action(s) in the `Pyro.Ash.Extensions.Resource` extension.
    """
    use Pyro.Ash.Extensions.Resource.Schema

    @type t :: %__MODULE__{}
    defstruct [:name, :label, :description, :class, :fields]

    @schema [
      name: [
        type: {:wrap_list, :atom},
        required: true,
        doc: "The action name(s) for this form."
      ],
      label: [
        type: :string,
        required: false,
        doc: "The label for this form (defaults to capitalized name)."
      ],
      description: [
        type: :string,
        required: false,
        doc: "The description for this form (defaults to action's description)."
      ],
      class: [
        type: css_class_schema_type(),
        required: false,
        doc: "Customize form classes."
      ]
    ]

    @doc false
    def schema, do: @schema
  end
end
