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
      :cell_class,
      :class,
      :description,
      :label,
      :name,
      :path,
      :render_cell,
      :sortable?,
      :type,
      :resource_field_type
    ]

    @type t :: %__MODULE__{
            cell_class: binary() | fun(),
            class: binary() | fun(),
            description: binary(),
            label: binary(),
            name: atom(),
            path: binary(),
            render_cell: (map() -> binary()),
            sortable?: boolean(),
            type: :default,
            resource_field_type:
              :attribute
              | :calculation
              | :aggregate
              | :has_one
              | :belongs_to
              | :has_many
              | :many_to_many
          }
    @schema [
      cell_class: [type: css_class_schema_type(), required: false, doc: "Customize cell class."],
      class: [type: css_class_schema_type(), required: false, doc: "Customize header class."],
      description: [
        type: :string,
        required: false,
        doc: "Override the default extracted description."
      ],
      label: [
        type: :string,
        required: false,
        doc: "The label of the column (defaults to capitalized name)."
      ],
      name: [type: :atom, required: true, doc: "The name of the column."],
      path: [
        type: {:list, :atom},
        required: false,
        doc: "Append to the root path (nested paths are appended)."
      ],
      render_cell: [type: {:fun, 1}, default: &__MODULE__.render_cell/1],
      sortable?: [
        type: :boolean,
        required: false,
        default: true,
        doc:
          "Set to false to disable sorting. Note: If it it is not technically sortable, it will automatically be set to false."
      ],
      type: [
        type: {:in, [:default]},
        required: false,
        doc: "The type of the the column.",
        default: :default
      ]
    ]

    def render_cell(%{row: row, col: %{type: :default, name: name}}) do
      Map.get(row, name)
    end

    @doc false
    def schema, do: @schema
  end
end
