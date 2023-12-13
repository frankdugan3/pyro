if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Info do
    @moduledoc """
    Helpers to introspect the `Pyro.Ash.Extensions.Resource` Ash extension. Intended for use in components that automatically build UI from resource configuration.
    """

    @doc """
    Returns the form fields defined in the `Pyro.Ash.Extensions.Resource` extension for the given action.

    ## Examples

        iex> form_for(Pyro.Ash.Extensions.Resource.InfoTest.User, :create) |> Map.get(:fields) |> Enum.map(& &1.name)
        [:primary, :authorization, :friendships, :notes]
    """
    @spec form_for(Ash.Resource.t(), atom()) ::
            [
              Pyro.Ash.Extensions.Resource.Form.Field.t()
              | Pyro.Ash.Extensions.Resource.Form.FieldGroup.t()
            ]
            | nil
    def form_for(resource, action_name) do
      resource
      |> Spark.Dsl.Extension.get_entities([:pyro, :form])
      |> Enum.find(fn action ->
        action.name == action_name
      end)
    end

    @doc """
    Returns the page defined in the `Pyro.Ash.Extensions.Resource` extension for the given page name.

    ## Examples

        iex> page_for(Pyro.Ash.Extensions.Resource.InfoTest.User, :list) |> Enum.map(& &1.name)
        :list
    """
    @spec page_for(Ash.Resource.t(), atom()) :: Pyro.Ash.Extensions.Resource.LiveView.Page | nil
    def page_for(resource, page_name) do
      resource
      |> Spark.Dsl.Extension.get_entities([:pyro, :live_view])
      |> Enum.find(fn page ->
        page.name == page_name
      end)
    end

    @doc """
    Returns the data table defined in the `Pyro.Ash.Extensions.Resource` extension for the given action.

    ## Examples

        iex> data_table_for(Pyro.Ash.Extensions.Resource.InfoTest.User, :list) |> Enum.map(& &1.name)
        [:list]
    """
    @spec data_table_for(Ash.Resource.t(), atom()) ::
            [
              Pyro.Ash.Extensions.Resource.DataTable
            ]
            | nil
    def data_table_for(resource, action_name) do
      resource
      |> Spark.Dsl.Extension.get_entities([:pyro, :data_table])
      |> Enum.find(fn action ->
        action.name == action_name
      end)
    end
  end
end
