defmodule Pyro.Schema.LiveComponent do
  @moduledoc """
  A DSL schema that maps to `Phoenix.LiveComponent`, with a few extra features.
  """

  @type t :: %__MODULE__{
          name: atom(),
          doc: binary() | nil,
          variables: map(),
          hooks: list(Pyro.Schema.Hook.t()),
          attrs: list(Pyro.Schema.Attr.t()),
          slots: list(Pyro.Schema.Slot.t()),
          classes: list(Pyro.Schema.Class.t()),
          template: Pyro.Component.Template.t(),
          components: list(Pyro.Schema.Component.t())
        }

  defstruct [
    :name,
    :doc,
    :template,
    variables: %{},
    hooks: [],
    attrs: [],
    slots: [],
    classes: [],
    components: []
  ]

  @schema [
    name: [
      type: :atom,
      required: true,
      doc: "name of the live component"
    ],
    variables: Pyro.Schema.Variable.schema(),
    template: Pyro.Component.Template.sigilh_schema(),
    doc: [
      type: :string,
      required: false,
      doc: "documentation for the live component"
    ]
  ]
  @doc false
  def schema, do: @schema
end
