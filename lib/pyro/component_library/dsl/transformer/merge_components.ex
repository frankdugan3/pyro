defmodule Pyro.ComponentLibrary.Dsl.Transformer.MergeComponents do
  @moduledoc false
  use Spark.Dsl.Transformer

  alias Pyro.ComponentLibrary.Dsl.Calc
  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.Global
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Pyro.ComponentLibrary.Dsl.Prop
  alias Spark.Dsl.Extension
  alias Spark.Dsl.Transformer
  alias Spark.Error.DslError

  @impl true
  def transform(dsl) do
    if Transformer.get_persisted(dsl, :component_library?, false) do
      {:ok, dsl}
    else
      context = %{
        merge_libraries?: Transformer.get_persisted(dsl, :merge_libraries?, false),
        module: Transformer.get_persisted(dsl, :module),
        path: [:components]
      }

      library_components =
        for module <- Transformer.get_persisted(dsl, :component_libraries, []),
            %module{} = component when module in [Component, LiveComponent] <-
              Extension.get_entities(module, [:components]) do
          component
        end
        |> verify_unique_libraries(context)
        |> Enum.reduce(%{}, &merge_component(&1, &2, context))

      components =
        for %module{} = component when module in [Component, LiveComponent] <-
              Extension.get_entities(dsl, [:components]) do
          component
        end
        |> Enum.reduce(library_components, &merge_component(&1, &2, context))
        |> Map.values()

      dsl =
        Transformer.remove_entity(dsl, [:components], fn
          %Component{} -> true
          %LiveComponent{} -> true
          _ -> false
        end)

      dsl = Enum.reduce(components, dsl, &Transformer.add_entity(&2, [:components], &1))

      {:ok, dsl}
    end
  end

  defp verify_unique_libraries(components, context) do
    components
    |> Enum.frequencies_by(& &1.name)
    |> Enum.each(fn {name, count} ->
      if count > 1 do
        raise DslError.exception(
                module: context.module,
                path: context.path,
                message: """
                #{count} library components share the name #{inspect(name)}.

                If you intend to merge the libraries, set the Pyro option `merge_libraries?: true`
                """
              )
      end
    end)

    components
  end

  defp merge_component(%LiveComponent{} = live_component, acc, context) do
    acc
    |> Map.put_new(live_component.name, live_component)
    |> Map.update!(live_component.name, fn old_live_component ->
      context = merge_context(context, old_live_component, live_component)

      old_live_component
      |> merge_doc(live_component)
      |> Map.update!(:assigns, &merge_assigns(&1, live_component.assigns, context))
      |> Map.update!(:slots, &merge_slots(&1, live_component.slots, context))
      |> Map.update!(:components, fn old_components ->
        (old_components ++ live_component.components)
        |> Enum.reduce(%{}, &merge_component(&1, &2, context))
        |> Map.values()
      end)
    end)
  end

  defp merge_component(%Component{} = component, acc, context) do
    acc
    |> Map.put_new(component.name, component)
    |> Map.update!(component.name, fn old_component ->
      context = merge_context(context, old_component, component)

      old_component
      |> maybe_override(:private?, component)
      |> merge_doc(component)
      |> Map.update!(:assigns, &merge_assigns(&1, component.assigns, context))
      |> Map.update!(:slots, &merge_slots(&1, component.slots, context))
    end)
  end

  defp merge_assigns(old_assigns, new_assigns, context) do
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
          context = merge_context(context, old_prop, prop)

          old_prop
          |> Map.put(:slot, Map.get(context, :slot))
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

  defp merge_slots(old_slots, new_slots, context) do
    (old_slots ++ new_slots)
    |> Enum.reduce(%{}, fn slot, slots ->
      slots
      |> Map.put_new(slot.name, slot)
      |> Map.update!(slot.name, &merge_slot(&1, slot, context))
    end)
    |> Map.values()
  end

  defp merge_slot(old_slot, slot, context) do
    context = merge_context(context, old_slot, slot)

    old_slot
    |> maybe_override(:required, slot)
    |> maybe_override(:validate_attrs, slot)
    |> merge_doc(slot)
    |> Map.update!(:attrs, fn old_attrs ->
      Map.put(context, :slot, old_slot.name)
      merge_assigns(old_attrs, slot.attrs, context)
    end)
  end

  defp merge_context(context, _old_entity, _new_entity) do
    context
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
