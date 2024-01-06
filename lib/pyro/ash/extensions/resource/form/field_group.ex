if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Form.FieldGroup do
    @moduledoc """
    A group of form fields in the `Pyro.Ash.Extensions.Resource` extension.
    """

    use Pyro.Ash.Extensions.Resource.Schema

    defstruct [:name, :label, :class, :path, :fields]

    @type t :: %__MODULE__{
            name: String.t(),
            label: String.t(),
            class: String.t(),
            path: [atom()],
            fields: [Pyro.Ash.Extensions.Resource.Form.Field.t()]
          }

    @schema [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the field group."
      ],
      label: [
        type: :string,
        required: false,
        doc: "The label of this group (defaults to capitalized name)."
      ],
      class: [
        type: css_class_schema_type(),
        required: false,
        doc: "Customize class."
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
