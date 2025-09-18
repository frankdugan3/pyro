defmodule Pyro.Transformer.MergeComponents do
  @moduledoc false
  use Pyro.Transformer

  alias Pyro.ComponentLibrary.Dsl.Calc
  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.Global
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Pyro.ComponentLibrary.Dsl.Prop

  @impl true
  def transform(dsl_state) do
    if Transformer.get_persisted(dsl_state, :component_library?, false) do
      {:ok, dsl_state}
    else
      scope = %{
        module: Transformer.get_persisted(dsl_state, :module)
      }

      components =
        [
          dsl_state
          |> Transformer.get_persisted(:component_libraries)
          |> Enum.map(fn module -> Pyro.Info.components(module) end),
          # TODO: Validate component libraries have distinct component and live_component names unless merge_libraries? = true
          Pyro.Info.components(dsl_state)
        ]
        |> List.flatten()
        |> Enum.reduce(%{}, &merge_component(&1, &2, scope))
        |> Map.values()

      live_components =
        [
          dsl_state
          |> Transformer.get_persisted(:component_libraries)
          |> Enum.map(fn module -> module |> Pyro.Info.live_components() end),
          Pyro.Info.live_components(dsl_state)
        ]
        |> List.flatten()
        |> Enum.reduce(%{}, &merge_live_component(&1, &2, scope))
        |> Map.values()

      dsl_state =
        dsl_state
        |> replace_components(components)
        |> replace_live_components(live_components)

      {:ok, dsl_state}
    end
  end

  defp merge_live_component(%LiveComponent{} = live_component, acc, scope) do
    acc
    |> Map.put_new(live_component.name, live_component)
    |> Map.update!(live_component.name, fn old_live_component ->
      scope = merge_scope(scope, old_live_component, live_component)

      old_live_component
      |> merge_doc(live_component)
      |> Map.update!(:assigns, &merge_assigns(&1, live_component.assigns, scope))
      |> Map.update!(:slots, &merge_slots(&1, live_component.slots, scope))
      |> Map.update!(:components, fn old_components ->
        (old_components ++ live_component.components)
        |> Enum.reduce(%{}, &merge_component(&1, &2, scope))
        |> Map.values()
      end)
    end)
  end

  defp merge_component(%Component{} = component, acc, scope) do
    acc
    |> Map.put_new(component.name, component)
    |> Map.update!(component.name, fn old_component ->
      scope = merge_scope(scope, old_component, component)

      old_component
      |> maybe_override(:private?, component)
      |> merge_doc(component)
      |> Map.update!(:assigns, &merge_assigns(&1, component.assigns, scope))
      |> Map.update!(:slots, &merge_slots(&1, component.slots, scope))
    end)
  end

  defp merge_assigns(old_assigns, new_assigns, scope) do
    (old_assigns ++
       new_assigns)
    |> Enum.reduce(%{}, fn
      %Global{} = global, assigns ->
        assigns
        |> Map.put_new(global.name, global)
        |> Map.update!(global.name, fn old_global ->
          old_global
          |> maybe_override(:include, global)
          |> maybe_override(:skip_template_validation?, global)
          |> merge_doc(global)
        end)

      %Calc{} = calc, assigns ->
        assigns
        |> Map.put_new(calc.name, calc)
        |> Map.update!(calc.name, fn old_calc ->
          maybe_override(old_calc, :calculation, calc)
        end)

      %Prop{} = prop, assigns ->
        assigns
        |> Map.put_new(prop.name, prop)
        |> Map.update!(prop.name, fn old_prop ->
          scope = merge_scope(scope, old_prop, prop)

          old_prop
          |> Map.put(:slot, Map.get(scope, :slot))
          |> maybe_override(:type, prop)
          |> maybe_override(:required, prop)
          |> maybe_override(:default, prop)
          |> maybe_override(:examples, prop)
          |> maybe_override(:values, prop)
          |> merge_doc(prop)
        end)
    end)
    |> Map.values()
  end

  defp merge_slots(old_slots, new_slots, scope) do
    (old_slots ++ new_slots)
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
    |> maybe_override(:required, slot)
    |> maybe_override(:validate_attrs, slot)
    |> merge_doc(slot)
    |> Map.update!(:attrs, fn old_attrs ->
      Map.put(scope, :slot, old_slot.name)
      merge_assigns(old_attrs, slot.attrs, scope)
    end)
  end

  defp merge_scope(scope, _old_entity, _new_entity) do
    scope
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
