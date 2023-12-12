if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Resource.LiveView.Page.Create do
    @moduledoc """
    A LiveView page.
    """
    @type t :: %__MODULE__{}
    defstruct [
      :live_action,
      :display_as,
      :action,
      :label,
      :description,
      :class,
      :path_key,
      :identity
    ]

    @schema [
      live_action: [
        type: :atom,
        required: true,
        doc: "The live action for this action."
      ],
      display_as: [
        type: {:one_of, [:form]},
        required: false,
        default: :form,
        doc: "How to display the action."
      ],
      action: [
        type: :atom,
        required: true,
        doc: "The action to use to load list of data."
      ],
      label: [
        type: :string,
        required: false,
        doc: "The label for this action (defaults to humanized live_action)."
      ],
      description: [
        type: {:or, [:string, {:one_of, [:inherit]}]},
        required: false,
        doc: "The description for this action."
      ],
      class: [
        type: :string,
        required: false,
        doc: "Customize action classes."
      ],
      path_key: [
        required: false,
        type: :string,
        doc: "The route path key for this action (no slashes)."
      ],
      identity: [
        required: false,
        type: {:or, [:atom, {:list, :atom}]},
        default: :id,
        doc: "The identity used to load the record."
      ]
    ]

    @doc false
    def schema, do: @schema
  end
end
