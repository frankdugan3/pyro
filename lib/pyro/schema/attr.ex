defmodule Pyro.Schema.Attr do
  @moduledoc """
  A DSL schema that maps to `Phoenix.Component.attr/3`, with a few extra features.
  """

  @typedoc """
  Attribute DSL entity.
  """
  @type t :: %__MODULE__{
          name: atom(),
          type:
            :any
            | :string
            | :atom
            | :boolean
            | :integer
            | :float
            | :list
            | :map
            | :global
            | module(),
          slot: atom() | nil,
          calculate: (map() -> any()) | nil,
          required: boolean(),
          default: any(),
          examples: list() | nil,
          values: list() | Pyro.Component.Template.expand_var() | nil,
          doc: binary() | nil,
          variables: map()
        }

  defstruct [
    :name,
    :type,
    :slot,
    :calculate,
    :required,
    :default,
    :examples,
    :values,
    :doc,
    variables: %{}
  ]

  @schema [
    name: [
      type: :atom,
      required: true,
      doc: "name of the attribute"
    ],
    variables: Pyro.Schema.Variable.schema(),
    type: [
      type:
        {:or,
         [
           {:one_of, [:any, :string, :atom, :boolean, :integer, :float, :list, :map, :global]},
           :struct
         ]},
      doc: "type of the attribute (default: `:any`)"
    ],
    calculate: [
      type: {:fun, [:map], :any},
      doc: "arity-1 function that recieves `assigns`, setting the value on render",
      snippet: """
      fn assigns ->
        ${0}
      end
      """
    ],
    required: [
      type: :boolean,
      doc: "marks attribute as required"
    ],
    default: [
      type: :any,
      doc: "default value for the attribute"
    ],
    examples: [
      type: {:wrap_list, :any},
      doc: "document a non-exhaustive list of accepted values"
    ],
    values: [
      type: {:or, [{:list, :any}, Pyro.Component.Template.expand_var_schema()]},
      doc: "exhaustive list of accepted values"
    ],
    doc: [
      type: :string,
      doc: "documentation for the attribute"
    ]
  ]

  @doc false
  def schema, do: @schema
end
