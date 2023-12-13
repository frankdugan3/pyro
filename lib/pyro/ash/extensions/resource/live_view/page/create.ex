if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.LiveView.Page.Create do
    @moduledoc """
    A LiveView page.
    """

    use Pyro.Ash.Extensions.Resource.Schema

    @type t :: %__MODULE__{}
    defstruct [
      :path,
      :live_action,
      :action,
      :display_as,
      :label,
      :description,
      :class,
      :identity
    ]

    @schema [
      path: [
        required: true,
        type: :string,
        doc: "The route path for this action."
      ],
      live_action: [
        type: :atom,
        required: true,
        doc: "The live action for this action."
      ],
      action: [
        type: :atom,
        required: true,
        doc: "The action to use to create the record."
      ],
      display_as: [
        type: {:one_of, [:form]},
        required: false,
        default: :form,
        doc: "How to display the action."
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
        type: css_class_type(),
        required: false,
        doc: "Customize action classes."
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
