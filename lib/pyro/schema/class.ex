defmodule Pyro.Schema.Class do
  @moduledoc """
  A DSL schema for CSS class attributes.
  """

  @type t :: %__MODULE__{
          name: atom(),
          base_class: Pyro.Component.Template.t() | nil,
          template: Pyro.Component.Template.t() | nil,
          doc: String.t() | nil,
          normalizer: (any() -> binary()) | nil,
          variants: list(atom()) | (map() -> any()),
          variables: map(),
          strategies: list(Pyro.Schema.ClassStrategy.t())
        }

  defstruct [
    :name,
    :base_class,
    :doc,
    :normalizer,
    :variants,
    :template,
    variables: %{},
    strategies: []
  ]

  @css_template_schema Pyro.Component.Template.sigile_schema(
                         doc: "CSS template (compile-time)",
                         snippet: ~S'''
                         ~E"""
                         .${1|<%= base_class %>|} {
                           ${0}
                         }
                         """
                         '''
                       )

  @base_class_schema Pyro.Component.Template.sigile_schema(
                       doc: "retained class (compile-time)",
                       snippet: ~S'''
                       ~E|<%= vars.prefix %><%= component %>${1}|${0}
                       '''
                     )

  @variants_schema [
    type: {:or, [{:wrap_list, :atom}, {:fun, [:map], :any}]},
    required: false,
    doc: "manage class variants (runtime)",
    snippet: """
    fn assigns ->
      [
        ${0}
      ]
    end
    """
  ]

  @normalizer_schema [
    type: {:fun, [:any], :string},
    required: false,
    doc: "function to pass the classes through to normalize the value (runtime)",
    snippet: "&Pyro.Component.Css.classes/1"
  ]

  @schema [
    name: [
      type: :atom,
      required: true,
      doc: "name of the CSS class attribute"
    ],
    variables: Pyro.Schema.Variable.schema(),
    base_class: @base_class_schema,
    template: @css_template_schema,
    variants: @variants_schema,
    normalizer: @normalizer_schema,
    doc: [
      type: :string,
      required: false,
      doc: "documentation for the attribute"
    ]
  ]

  @doc false
  def schema, do: @schema

  @doc false
  def base_class_schema, do: @base_class_schema

  @doc false
  def variants_schema, do: @variants_schema

  @doc false
  def normalizer_schema, do: @normalizer_schema

  @doc false
  def template_schema(opts \\ []) do
    Keyword.merge(@css_template_schema, opts)
  end
end
