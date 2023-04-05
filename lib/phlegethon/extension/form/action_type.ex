if Code.ensure_loaded?(Ash) do
  defmodule Phlegethon.Resource.Form.ActionType do
    @moduledoc """
    A group of form for action(s) in the `Phlegethon.Resource` extension.
    """
    defstruct [:name, :class, :fields]

    @action_types {:one_of, [:create, :update, :destroy]}

    @default_class "grid"

    @schema [
      name: [
        type: {:or, [@action_types, {:list, @action_types}]},
        required: true,
        doc: "The action type(s) for this form."
      ],
      class: [
        type: :string,
        required: false,
        doc: "Merge/override the default class (defaults to \"#{@default_class}\")."
      ]
    ]

    def default_class, do: @default_class

    def schema, do: @schema
  end
end
