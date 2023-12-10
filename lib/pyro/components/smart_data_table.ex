if Code.ensure_loaded?(AshPhoenix) do
  defmodule Pyro.Components.SmartDataTable do
    @moduledoc """
    A smart component that auto-renders Forms for Ash from a given pyro DSL configuration.
    """

    use Pyro.Component

    # import Pyro.Components.DataTable, only: [data_table: 1]

    alias Pyro.Resource.Info, as: UI
    alias Ash.Resource.Info, as: ResourceInfo

    require Ash.Query

    @doc """
    Renders a smart Ash form.
    """

    attr :overrides, :list, default: nil, doc: @overrides_attr_doc
    attr :action_info, :any, default: :unassigned
    attr :pyro_data_table, :any, default: :unassigned
    attr :class, :css_classes, overridable: true, required: true
    attr :resource, :atom, required: true, doc: "the resource of the form"
    attr :actor, :map, default: nil, doc: "the actor to be passed to actions"
    attr :tz, :string, default: "Etc/UTC", doc: "timezone"

    def smart_data_table(%{action_info: :unassigned, for: %{action: action}} = assigns) do
      assigns
      |> assign(:action_info, ResourceInfo.action(assigns[:resource], action))
      |> smart_data_table()
    end

    def smart_data_table(%{pyro_data_table: :unassigned, for: %{action: action}} = assigns) do
      pyro_data_table = UI.data_table_for(assigns[:resource], action)

      if pyro_data_table == nil,
        do:
          raise("""
          Resource #{assigns[:resource]} does not have a pyro form defined for the action #{action}!
          """)

      assigns
      |> assign(:pyro_data_table, pyro_data_table)
      |> smart_data_table()
    end

    def smart_data_table(assigns) do
      assigns = assign_overridables(assigns)

      ~H"""
      <div></div>
      """
    end
  end
end
