if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.DataTable.Column do
    @moduledoc ~s'''
    The configuration of a data table column in the `Pyro.Ash.Extensions.Resource` extension.

    By default, the `tbody` cell will be rendered with `render_cell/1`. You can also change the `:type` option to specify special kinds of rendering.

    For bespoke rendering needs, you can provide a custom component inline or as a function capture:

    ```elixir
    import Phoenix.Component, only: [sigil_H: 2]
    column :code do
      class "whitespace-nowrap"
      render_cell fn assigns ->
        ~H"""
        <Pyro.Components.Core.icon name="hero-rocket-launch" />
        <%= Map.get(@row, @col[:name]) %>
        """
      end
    end
    ```
    '''

    use Pyro.Ash.Extensions.Resource.Schema

    defstruct [
      :name,
      :type,
      :render_cell,
      :label,
      :description,
      :path,
      :class,
      :sortable?,
      :cell_class
    ]

    @type t :: %__MODULE__{
            name: atom(),
            type: :default,
            render_cell: (map() -> binary()),
            label: binary(),
            description: binary(),
            class: binary() | fun(),
            cell_class: binary() | fun(),
            path: binary()
          }
    @schema [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the column."
      ],
      type: [
        type: {:in, [:default]},
        required: false,
        doc: "The type of the the column.",
        default: :default
      ],
      render_cell: [
        type: {:fun, 1},
        default: &__MODULE__.render_cell/1
      ],
      label: [
        type: :string,
        required: false,
        doc: "The label of the column (defaults to capitalized name)."
      ],
      description: [
        type: :string,
        required: false,
        doc: "Override the default extracted description."
      ],
      class: [
        type: css_class_type(),
        required: false,
        doc: "Customize header class."
      ],
      cell_class: [
        type: css_class_type(),
        required: false,
        doc: "Customize cell class."
      ],
      sortable?: [
        type: :boolean,
        required: false,
        # TODO: Need to check/validate this, hack defaulting to true for now.
        default: true,
        doc: "Allow this column to be sortable (defaults to true if it is technically sortable)."
      ],
      path: [
        type: {:list, :atom},
        required: false,
        doc: "Append to the root path (nested paths are appended)."
      ]
    ]

    def render_cell(%{row: row, col: %{type: :default, name: name}}) do
      Map.get(row, name)
    end

    @doc false
    def schema, do: @schema
  end
end
