defmodule Pyro.Schema.Slot do
  @moduledoc """
  A DSL schema that maps to `Phoenix.Component.slot/3`, with a few extra features.
  """

  @type t :: %__MODULE__{
          name: atom(),
          required: boolean(),
          validate_attrs: boolean(),
          doc: String.t() | nil,
          variables: map(),
          classes: list(Pyro.Schema.Class.t()),
          attrs: list(Pyro.Schema.Attr.t())
        }

  defstruct [
    :name,
    :required,
    :validate_attrs,
    :doc,
    variables: %{},
    classes: [],
    attrs: []
  ]

  @schema [
    name: [
      type: :atom,
      required: true,
      doc: "name of the slot"
    ],
    required: [
      type: :boolean,
      doc: "marks slot as required"
    ],
    validate_attrs: [
      type: :boolean,
      doc: "validate attributes passed to slot (default: `true`)"
    ],
    doc: [
      type: :string,
      doc: "documentation for the slot"
    ],
    variables: Pyro.Schema.Variable.schema()
  ]

  @doc false
  def schema, do: @schema
end
