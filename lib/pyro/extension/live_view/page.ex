if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Resource.Page do
    @moduledoc """
    A data table for action(s) of a given type in the `Pyro.Resource` extension.
    """
    @type t :: %__MODULE__{}
    defstruct [:name, :actions, :label, :description, :class, :route_path]

    @schema [
      name: [
        type: :atom,
        required: true,
        doc: "The name for this page."
      ],
      actions: [
        type: {:list, :atom},
        required: true,
        doc: "The actions allowed on this page."
      ],
      label: [
        type: :string,
        required: false,
        doc: "The label for this data table (defaults to capitalized name)."
      ],
      description: [
        type: :string,
        required: false,
        doc: "The description for this data table (defaults to action's description)."
      ],
      class: [
        type: :string,
        required: false,
        doc: "Merge/override the default data table classes."
      ],
      route_path: [
        required: true,
        type: :string,
        doc: "The route path for the page"
      ]
    ]

    @doc false
    def schema, do: @schema
  end
end
