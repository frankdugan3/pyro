defmodule Pyro.Transformer.MergeComponents do
  @moduledoc false
  use Pyro.Transformer

  @impl true
  def after?(module) do
    module in [Pyro.Transformer.MergeSectionVariables]
  end

  @impl true
  def transform(dsl_state) do
    scope = %{
      module: Transformer.get_persisted(dsl_state, :module),
      variables: Transformer.get_option(dsl_state, [:components], :variables, %{})
    }

    components =
      [
        dsl_state
        |> Transformer.get_persisted(:component_libraries)
        |> Enum.map(fn module ->
          module
          |> Pyro.Info.components()
          |> Enum.map(&merge_component_variables(&1, scope))
        end),
        Pyro.Info.components(dsl_state)
      ]
      |> List.flatten()
      |> Enum.reduce(
        %{},
        &merge_component(&1, &2, scope)
      )
      |> Map.values()

    live_components =
      [
        dsl_state
        |> Transformer.get_persisted(:component_libraries)
        |> Enum.map(fn module ->
          module
          |> Pyro.Info.live_components()
          |> Enum.map(&merge_live_component_variables(&1, scope))
        end),
        Pyro.Info.live_components(dsl_state)
      ]
      |> List.flatten()
      |> Enum.reduce(
        %{},
        &merge_live_component(&1, &2, scope)
      )
      |> Map.values()

    dsl_state =
      dsl_state
      |> replace_components(components)
      |> replace_live_components(live_components)

    {:ok, dsl_state}
  end

  defp merge_live_component(%Pyro.Schema.LiveComponent{} = live_component, acc, scope) do
    acc
    |> Map.put_new(live_component.name, live_component)
    |> Map.update!(live_component.name, fn old_live_component ->
      scope = merge_scope(scope, old_live_component, live_component)

      old_live_component
      |> Map.put(:variables, scope.variables)
      |> maybe_override(:template, live_component)
      |> merge_doc(live_component)
      |> Map.update!(:hooks, &merge_hooks(&1, live_component.hooks, scope))
      |> Map.update!(:attrs, &merge_attrs(&1, live_component.attrs, scope))
      |> Map.update!(:slots, &merge_slots(&1, live_component.slots, scope))
      |> Map.update!(:components, fn old_components ->
        (old_components ++ live_component.components)
        |> Enum.reduce(
          %{},
          &merge_component(&1, &2, scope)
        )
        |> Map.values()
      end)
    end)
  end

  defp merge_component(%Pyro.Schema.Component{} = component, acc, scope) do
    acc
    |> Map.put_new(component.name, component)
    |> Map.update!(component.name, fn old_component ->
      scope = merge_scope(scope, old_component, component)

      old_component
      |> Map.put(:variables, scope.variables)
      |> maybe_override(:private?, component)
      |> maybe_override(:template, component)
      |> merge_doc(component)
      |> Map.update!(:hooks, &merge_hooks(&1, component.hooks, scope))
      |> Map.update!(:attrs, &merge_attrs(&1, component.attrs, scope))
      |> Map.update!(:slots, &merge_slots(&1, component.slots, scope))
    end)
  end

  defp merge_hooks(old_hooks, new_hooks, scope) do
    (old_hooks ++
       new_hooks)
    |> Enum.reduce(%{}, fn hook, hooks ->
      hooks
      |> Map.put_new(hook.name, hook)
      |> Map.update!(hook.name, fn old_hook ->
        scope = merge_scope(scope, old_hook, hook)

        old_hook
        |> Map.put(:variables, scope.variables)
        |> maybe_override(:template, hook)
        |> merge_doc(hook)
      end)
    end)
    |> Map.values()
  end

  defp merge_attrs(old_attrs, new_attrs, scope) do
    (old_attrs ++
       new_attrs)
    |> Enum.reduce(%{}, fn attr, attrs ->
      attrs
      |> Map.put_new(attr.name, attr)
      |> Map.update!(attr.name, fn old_attr ->
        scope = merge_scope(scope, old_attr, attr)

        old_attr
        |> Map.put(:variables, scope.variables)
        |> Map.put(:slot, Map.get(scope, :slot))
        |> maybe_override(:type, attr)
        |> maybe_override(:calculate, attr)
        |> maybe_override(:required, attr)
        |> maybe_override(:default, attr)
        |> maybe_override(:examples, attr)
        |> maybe_override(:values, attr)
        |> merge_doc(attr)
      end)
    end)
    |> Map.values()
  end

  # defp merge_classes(old_classes, new_classes, scope) do
  #   (old_classes ++
  #      new_classes)
  #   |> Enum.reduce(%{}, fn class, classes ->
  #     classes
  #     |> Map.put_new(class.name, class)
  #     |> Map.update!(class.name, &merge_class(&1, class, scope))
  #   end)
  #   |> Map.values()
  # end
  #
  # defp merge_class(old_class, class, scope) do
  #   scope = merge_scope(scope, old_class, class)
  #
  #   merged_class =
  #     old_class
  #     |> Map.put(:variables, scope.variables)
  #     |> maybe_override(:base_class, class)
  #     |> maybe_override(:template, class)
  #     |> maybe_override(:normalizer, class)
  #     |> merge_doc(class)
  #
  #   Map.update!(merged_class, :strategies, fn old_strategies ->
  #     scope =
  #       scope
  #       |> Map.put(:base_class, merged_class.base_class)
  #       |> Map.put(:template, merged_class.template)
  #       |> Map.put(:normalizer, merged_class.normalizer)
  #       |> Map.put(:variants, merged_class.variants)
  #
  #     merge_class_strategies(old_strategies, class.strategies, scope)
  #   end)
  # end
  #
  # defp merge_class_strategies(old_class_strategies, new_class_strategies, scope) do
  #   (old_class_strategies ++
  #      new_class_strategies)
  #   |> Enum.reduce(%{}, fn strategy, class_strategies ->
  #     class_strategies
  #     |> Map.put_new(strategy.name, strategy)
  #     |> Map.update!(strategy.name, &merge_class_strategy(&1, strategy, scope))
  #   end)
  #   |> Map.values()
  # end
  #
  # defp merge_class_strategy(old_strategy, strategy, scope) do
  #   scope = merge_scope(scope, old_strategy, strategy)
  #
  #   old_strategy
  #   |> Map.put(:variables, scope.variables)
  #   |> maybe_override(:base_class, strategy)
  #   |> maybe_fallback_scope(:base_class, scope)
  #   |> maybe_override(:template, strategy)
  #   |> maybe_fallback_scope(:template, scope)
  #   |> maybe_override(:normalizer, strategy)
  #   |> maybe_fallback_scope(:normalizer, scope)
  #   |> maybe_override(:variants, strategy)
  #   |> maybe_fallback_scope(:variants, scope)
  #   |> merge_doc(strategy)
  # end

  defp merge_slots(old_slots, new_slots, scope) do
    (old_slots ++
       new_slots)
    |> Enum.reduce(%{}, fn slot, slots ->
      slots
      |> Map.put_new(slot.name, slot)
      |> Map.update!(slot.name, &merge_slot(&1, slot, scope))
    end)
    |> Map.values()
  end

  defp merge_slot(old_slot, slot, scope) do
    scope = merge_scope(scope, old_slot, slot)

    old_slot
    |> Map.put(:variables, scope.variables)
    |> maybe_override(:required, slot)
    |> maybe_override(:validate_attrs, slot)
    |> merge_doc(slot)
    |> Map.update!(:attrs, fn old_attrs ->
      Map.put(scope, :slot, old_slot.name)
      merge_attrs(old_attrs, slot.attrs, scope)
    end)
  end

  defp merge_live_component_variables(%Pyro.Schema.LiveComponent{} = live_component, scope) do
    live_component
    |> apply_variables(scope)
    |> Map.update!(:attrs, fn attrs -> Enum.map(attrs, &merge_attr_variables(&1, scope)) end)
    |> Map.update!(:slots, fn slots -> Enum.map(slots, &merge_slot_variables(&1, scope)) end)
    |> Map.update!(:classes, fn classes ->
      Enum.map(classes, &merge_class_variables(&1, scope))
    end)
    |> Map.update!(:components, fn components ->
      Enum.map(components, &merge_component_variables(&1, scope))
    end)
  end

  defp merge_component_variables(%Pyro.Schema.Component{} = component, scope) do
    component
    |> apply_variables(scope)
    |> Map.update!(:attrs, fn attrs -> Enum.map(attrs, &merge_attr_variables(&1, scope)) end)
    |> Map.update!(:slots, fn slots -> Enum.map(slots, &merge_slot_variables(&1, scope)) end)
    |> Map.update!(:classes, fn classes ->
      Enum.map(classes, &merge_class_variables(&1, scope))
    end)
  end

  defp merge_attr_variables(%Pyro.Schema.Attr{} = attr, scope) do
    apply_variables(attr, scope)
  end

  defp merge_class_variables(%Pyro.Schema.Class{} = class, scope) do
    class
    |> apply_variables(scope)
    |> Map.update!(:strategies, fn strategies ->
      Enum.map(strategies, &merge_class_strategy_variables(&1, scope))
    end)
  end

  defp merge_class_strategy_variables(%Pyro.Schema.ClassStrategy{} = strategy, scope) do
    apply_variables(strategy, scope)
  end

  defp merge_slot_variables(%Pyro.Schema.Slot{} = slot, scope) do
    slot
    |> apply_variables(scope)
    |> Map.update!(:attrs, fn attrs -> Enum.map(attrs, &merge_attr_variables(&1, scope)) end)
  end

  defp apply_variables(entity, scope) do
    Map.update!(entity, :variables, &Map.merge(&1, scope.variables))
  end

  defp merge_scope(scope, old_entity, new_entity) do
    Map.update!(
      scope,
      :variables,
      fn variables ->
        old_entity.variables
        |> Map.merge(variables)
        |> Map.merge(new_entity.variables)
      end
    )
  end

  defp maybe_fallback_scope(entity, key, scope) do
    Map.update!(entity, key, fn
      nil -> Map.get(scope, key)
      value -> value
    end)
  end

  defp merge_doc(old, new) do
    Map.update!(old, :doc, fn value -> value |> maybe_override(new.doc) |> maybe_trim() end)
  end

  defp maybe_override(old, key, new) do
    Map.update!(old, key, &maybe_override(&1, Map.get(new, key)))
  end

  defp maybe_override(_old, new) when not is_nil(new), do: new
  defp maybe_override(old, _new), do: old
  defp maybe_trim(value) when is_binary(value), do: String.trim(value)
  defp maybe_trim(value), do: value
end
