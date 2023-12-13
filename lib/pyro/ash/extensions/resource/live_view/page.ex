if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.LiveView.Page do
    @moduledoc """
    A LiveView page.
    """

    use Pyro.Ash.Extensions.Resource.Schema

    @type t :: %__MODULE__{}
    defstruct [:path, :name, :view_as, :class, :live_actions, :__identifier__]

    @schema [
      path: [
        required: true,
        type: :string,
        doc: "The route path for this page."
      ],
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
        type: css_class_type(),
        required: false,
        doc: "Customize page classes."
      ]
    ]

    @doc false
    def schema, do: @schema
  end
end