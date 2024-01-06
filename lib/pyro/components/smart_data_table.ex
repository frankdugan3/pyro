if Code.ensure_loaded?(AshPhoenix) do
  defmodule Pyro.Components.SmartDataTable do
    @moduledoc """
    A smart component that auto-renders Forms for Ash from a given pyro DSL configuration.
    """

    use Pyro.Components.SmartComponent

    import Pyro.Components.DataTable, only: [data_table: 1]

    @doc """
    Renders a smart data table.
    """

    attr :overrides, :list, default: nil, doc: @overrides_attr_doc
    attr :id, :string, required: true
    attr :pyro_data_table, Pyro.Ash.Extensions.Resource.DataTable.Action, required: true
    attr :rows, :list, required: true
    attr :sort, :list, required: true
    attr :display, :list, required: true
    attr :filter, :list, required: true
    attr :resource, :atom, required: true, doc: "the resource of the data table"
    attr :actor, :map, default: nil, doc: "the actor to be passed to actions"
    attr :tz, :string, default: "Etc/UTC", doc: "timezone"
    attr :class, :css_classes, overridable: true

    def smart_data_table(assigns) do
      assigns = assign_overridables(assigns)

      ~H"""
      <.data_table id={@id} rows={@rows} sort={@sort} class={smart_class(@class, assigns)}>
        <:col
          :let={row}
          :for={col <- display_columns(@pyro_data_table.columns, @display)}
          label={col.label}
          sort_key={if col.sortable?, do: col.name}
          class={smart_class(col.class, col)}
          cell_class={smart_class(col.cell_class, col)}
        >
          <%= apply(col.render_cell, [%{row: row, col: col}]) %>
        </:col>
      </.data_table>
      """
    end

    defp display_columns(columns, display) do
      Enum.map(display, fn name -> Enum.find(columns, fn column -> column.name == name end) end)
    end
  end
end
