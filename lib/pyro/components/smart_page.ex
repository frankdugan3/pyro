if Code.ensure_loaded?(AshPhoenix) do
  defmodule Pyro.Components.SmartPage do
    @moduledoc """
    A smart component that auto-renders Forms for Ash from a given pyro DSL configuration.
    """

    use Pyro.Component

    # import Pyro.Gettext
    # import Pyro.Components.Core, only: [button: 1, header: 1, input: 1]

    alias Pyro.Resource.Info, as: UI
    # alias Ash.Resource.Info, as: ResourceInfo

    require Ash.Query

    @doc """
    Renders a smart Ash form.
    """

    attr :overrides, :list, default: nil, doc: @overrides_attr_doc
    attr :class, :css_classes, overridable: true, required: true
    attr :pyro_page, :any, default: :unassigned
    attr :resource, :atom, required: true, doc: "the resource of the page"
    attr :page, :atom, required: true, doc: "the page of the resource to render"
    attr :actor, :map, default: nil, doc: "the actor to be passed to actions"
    attr :tz, :string, default: "Etc/UTC", doc: "timezone"

    def smart_page(%{pyro_page: :unassigned, page: page} = assigns) do
      pyro_page = UI.page_for(assigns[:resource], page)

      if pyro_page == nil,
        do:
          raise("""
          Resource #{assigns[:resource]} does not have a pyro page named #{inspect(page)}.
          """)

      assigns
      |> assign(:pyro_page, pyro_page)
      |> smart_page()
    end

    def smart_page(assigns) do
      assigns = assign_overridables(assigns)

      ~H"""
      <div></div>
      """
    end
  end
end
