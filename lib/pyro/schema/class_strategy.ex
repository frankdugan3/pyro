defmodule Pyro.Schema.ClassStrategy do
  @moduledoc """
  A DSL schema for a stratgy implementing a CSS class attribute.
  """

  @type t :: %__MODULE__{
          name: atom(),
          base_class: Pyro.Component.Template.t() | nil,
          template: Pyro.Component.Template.t() | nil,
          doc: String.t() | nil,
          normalizer: (any() -> binary()) | nil,
          variants: list(atom()) | (map() -> any()),
          variables: map()
        }

  defstruct [
    :name,
    :base_class,
    :doc,
    :normalizer,
    :variants,
    :template,
    variables: %{}
  ]

  @schema [
    name: [type: :atom, required: true, doc: "name of the CSS strategy"],
    variables: Pyro.Schema.Variable.schema(),
    base_class: Pyro.Schema.Class.base_class_schema(),
    template: Pyro.Schema.Class.template_schema(),
    variants: Pyro.Schema.Class.variants_schema(),
    normalizer: Pyro.Schema.Class.normalizer_schema(),
    doc: [type: :string, required: false, doc: "documentation for the class attribute"]
  ]

  @doc false
  def schema, do: @schema
end
