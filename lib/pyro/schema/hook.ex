defmodule Pyro.Schema.Hook do
  @moduledoc """
  A DSL schema for JS hooks.
  """

  @type t :: %__MODULE__{
          name: atom(),
          template: Pyro.Component.Template.t() | nil,
          doc: String.t() | nil,
          variables: map()
        }

  defstruct [
    :name,
    :doc,
    :template,
    variables: %{}
  ]

  @schema [
    name: [
      type: :string,
      required: true,
      doc: "name of the JS hook"
    ],
    variables: Pyro.Schema.Variable.schema(),
    template:
      Pyro.Component.Template.sigile_schema(
        required: true,
        doc: "JS hook template (compile-time)",
        snippet: ~S'''
        ~E"""
        // REMEMBER: Use this.pushEvent and this.handleEvent
        // to send to and receive events from server.
        // You can also define other functions in this object
        // and use it in the callbacks with this.*
        {
          mounted() { ${0} },
          // beforeUpdate() {},
          // updated() {},
          // destroyed() {},
          // disconnected() {},
          // reconnected() {},
        }
        """
        '''
      ),
    doc: [
      type: :string,
      required: false,
      doc: "documentation for the hook"
    ]
  ]

  @doc false
  def schema, do: @schema
end
