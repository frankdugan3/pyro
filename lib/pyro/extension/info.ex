if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Resource.Info do
    @moduledoc """
    Helpers to introspect the `Pyro.Resource` Ash extension. Intended for use in components that automatically build UI from resource configuration.
    """

    @doc """
    Returns the form fields defined in the `Pyro.Resource` extension for the given action.

    ## Examples

        iex> form_for(Pyro.Resource.InfoTest.User, :create) |> Map.get(:fields) |> Enum.map(& &1.name)
        [:primary, :authorization, :friendships, :notes]
    """
    @spec form_for(Ash.Resource.t(), atom()) :: [
            Pyro.Resource.Form.Field.t() | Pyro.Resource.Form.FieldGroup.t()
          ]
    def form_for(resource, action_name) do
      resource
      |> Spark.Dsl.Extension.get_entities([:pyro, :form])
      |> Enum.find(fn action ->
        action.name == action_name
      end)
    end
  end
end
