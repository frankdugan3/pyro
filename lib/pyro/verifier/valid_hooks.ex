defmodule Pyro.Verifier.ValidHooks do
  @moduledoc """
  Validate that all hooks:

  - are uniquely named
  - have a template defined
  - are referenced in the component
  """

  use Pyro.Verifier

  alias Pyro.Schema.Component
  alias Pyro.Schema.Hook
  alias Pyro.Schema.LiveComponent

  @impl true
  @doc false
  def verify(dsl_state) do
    results =
      verify_until_error(
        MapSet.new(),
        Verifier.get_entities(dsl_state, [:components]),
        &verify_component/3,
        %{path: [:components]}
      )

    case results do
      {:error, error} -> {:error, error}
      _ -> :ok
    end
  end

  defp verify_component(%LiveComponent{} = live_component, acc, scope) do
    scope = Map.put(scope, :path, scope.path ++ [:live_component, inspect(live_component.name)])

    acc
    |> verify_until_error(live_component.hooks, &verify_hook/3, scope)
    |> verify_until_error(live_component.components, &verify_component/3, scope)
  end

  defp verify_component(%Component{} = component, acc, scope) do
    scope =
      scope
      |> Map.put(:path, scope.path ++ [:component, inspect(component.name)])
      |> Map.put(:component, component)

    verify_until_error(acc, component.hooks, &verify_hook/3, scope)
  end

  defp verify_hook(%Hook{} = hook, acc, scope) do
    scope = Map.put(scope, :path, scope.path ++ [:hook, inspect(hook.name)])

    acc
    |> verify_until_error([hook], &verify_uniqueness/3, scope)
    |> verify_until_error([hook], &verify_template_defined/3, scope)
    |> verify_until_error([hook], &verify_referenced_in_component/3, scope)
  end

  defp verify_uniqueness(%Hook{name: name}, acc, scope) do
    if MapSet.member?(acc, name) do
      {:error,
       Spark.Error.DslError.exception(
         path: scope.path,
         message: """
         Hook #{name} is already defined.
         """
       )}
    else
      MapSet.put(acc, name)
    end
  end

  defp verify_template_defined(%Hook{name: name, template: template}, acc, scope) do
    if !template || !template.source || String.trim(template.source) == "" do
      {:error,
       Spark.Error.DslError.exception(
         path: scope.path,
         message: """
         Hook #{name} template is not implemented.
         """
       )}
    else
      acc
    end
  end

  defp verify_referenced_in_component(%Hook{name: name}, acc, scope) do
    if Regex.match?(~r/phx-hook=.*#{name}/, scope.component.template.source) do
      acc
    else
      {:error,
       Spark.Error.DslError.exception(
         path: scope.path,
         message: """
         Hook #{name} is not referenced in the component template.
         """
       )}
    end
  end
end
