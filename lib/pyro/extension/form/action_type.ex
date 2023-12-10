if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Resource.Form.ActionType do
    @moduledoc """
    A form for action(s) of a given type in the `Pyro.Resource` extension.
    """
    @type t :: %__MODULE__{}
    defstruct [:name, :class, :fields]

    @action_types {:one_of, [:create, :update]}

    @schema [
      name: [
        type: {:or, [@action_types, {:list, @action_types}]},
        required: true,
        doc: "The action type(s) for this form."
      ],
      class: [
        type: :string,
        required: false,
        doc: "Merge/override the default form classes."
      ]
    ]

    @doc false
    def schema, do: @schema
  end
end
