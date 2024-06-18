defmodule Pyro.Schema.Component do
  @moduledoc """
  A DSL schema that maps to `Phoenix.Component`, with a few extra features.
  """

  @type t :: %__MODULE__{
          name: atom(),
          private?: boolean(),
          variables: map(),
          hooks: list(Pyro.Schema.Hook.t()),
          attrs: list(Pyro.Schema.Attr.t()),
          slots: list(Pyro.Schema.Slot.t()),
          classes: list(Pyro.Schema.Class.t()),
          template: Pyro.Component.Template.t(),
          doc: String.t() | nil
        }

  defstruct [
    :name,
    :private?,
    :doc,
    :template,
    variables: %{},
    hooks: [],
    attrs: [],
    slots: [],
    classes: []
  ]

  @schema [
    name: [
      type: :atom,
      required: true,
      doc: "name of the component"
    ],
    variables: Pyro.Schema.Variable.schema(),
    private?: [
      type: :boolean,
      doc: "mark the component as private (default: `false`)"
    ],
    template: Pyro.Component.Template.sigilh_schema(),
    doc: [
      type: :string,
      doc: "documentation for the component"
    ]
  ]

  @doc false
  def schema, do: @schema
end
