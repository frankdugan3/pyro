if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Resource.LiveView.Page do
    @moduledoc """
    A LiveView page.
    """
    @type t :: %__MODULE__{}
    defstruct [:name, :view_as, :class, :path_key, :live_actions]

    @schema [
      name: [
        type: :atom,
        required: true,
        doc: "The live action for this page."
      ],
      view_as: [
        type: {:one_of, [:list_and_modal, :show_and_modal, :individual]},
        required: false,
        default: :list_and_modal,
        doc: """
        The view style of the page:
          - `:list_and_modal` - Always list view, show/create/edit in a modal
          - `:show_and_modal` - List view for list actions, show as a dedicated view, create/edit in a modal on show
          - `:individual` - All actions are a dedicated view
        """
      ],
      class: [
        type: :string,
        required: false,
        doc: "Customize page classes."
      ],
      path_key: [
        required: false,
        type: :string,
        doc: "The route path key for this page (no slashes)."
      ]
    ]

    @doc false
    def schema, do: @schema
  end
end
