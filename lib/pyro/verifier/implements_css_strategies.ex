# defmodule Pyro.Verifier.ImplementsCssStrategies do
#   @moduledoc """
#   Verify that all the CSS strategies in the `:implements_css_strategies` and the `:css_stragegy` are implemented.
#   """
#
#   use Pyro.Verifier
#
#   alias Pyro.Schema.Class
#   alias Pyro.Schema.ClassStrategy
#   alias Pyro.Schema.Component
#   alias Pyro.Schema.LiveComponent
#   alias Pyro.Schema.Slot
#
#   @impl true
#   @doc false
#   def verify(dsl_state) do
#     strategies =
#       [
#         Verifier.get_persisted(dsl_state, :css_strategy)
#         | Verifier.get_persisted(dsl_state, :implements_css_strategies)
#       ]
#       |> Enum.filter(&(&1 != nil))
#       |> Enum.uniq()
#
#     verify_until_error(
#       :ok,
#       strategies,
#       fn strategy, acc, scope ->
#         scope = Map.put(scope, :strategy, strategy)
#
#         verify_until_error(
#           acc,
#           Verifier.get_entities(dsl_state, [:components]),
#           &verify_component/3,
#           scope
#         )
#       end,
#       %{path: [:components]}
#     )
#   end
#
#   defp verify_component(%LiveComponent{} = live_component, acc, scope) do
#     scope = Map.put(scope, :path, scope.path ++ [:live_component, inspect(live_component.name)])
#
#     acc
#     |> verify_until_error(live_component.slots, &verify_slot/3, scope)
#     |> verify_until_error(live_component.classes, &verify_class/3, scope)
#     |> verify_until_error(live_component.components, &verify_component/3, scope)
#   end
#
#   defp verify_component(%Component{} = component, acc, scope) do
#     scope = Map.put(scope, :path, scope.path ++ [:component, inspect(component.name)])
#
#     acc
#     |> verify_until_error(component.slots, &verify_slot/3, scope)
#     |> verify_until_error(component.classes, &verify_class/3, scope)
#   end
#
#   defp verify_slot(%Slot{} = slot, acc, scope) do
#     scope = Map.put(scope, :path, scope.path ++ [:slot, inspect(slot.name)])
#
#     verify_until_error(acc, slot.classes, &verify_class/3, scope)
#   end
#
#   defp verify_class(%Class{} = class, acc, scope) do
#     strategy = scope.strategy
#
#     case Enum.find(class.strategies, fn %ClassStrategy{name: name} -> name == strategy end) do
#       nil ->
#         {:error,
#          Spark.Error.DslError.exception(
#            path: scope.path ++ [:class, inspect(class.name)],
#            message: """
#            Strategy #{strategy} is not implemented.
#            """
#          )}
#
#       _ ->
#         acc
#     end
#   end
# end
