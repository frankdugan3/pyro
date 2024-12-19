defmodule Pyro.Transformer.ApplyVariables do
  @moduledoc """
  Apply all the variable values to DSL.
  """

  use Pyro.Transformer

  require EEx

  @doc false
  @impl true
  def after?(module) do
    module in [Pyro.Transformer.MergeComponents]
  end

  @doc false
  @impl true
  def transform(dsl_state) do
    if Spark.Dsl.Extension.get_persisted(dsl_state, :library?) do
      {:ok, dsl_state}
    else
      scope = %{
        module: Transformer.get_persisted(dsl_state, :module),
        variables: Transformer.get_option(dsl_state, [:components], :variables, %{})
      }

      components =
        dsl_state
        |> Pyro.Info.components()
        |> Enum.map(&apply_component_variables(&1, scope))

      live_components =
        dsl_state
        |> Pyro.Info.live_components()
        |> Enum.map(&apply_live_component_variables(&1, scope))

      dsl_state =
        dsl_state
        |> replace_components(components)
        |> replace_live_components(live_components)

      {:ok, dsl_state}
    end
  end

  defp apply_live_component_variables(%Pyro.Schema.LiveComponent{} = live_component, scope) do
    scope = Map.put(scope, :live_component, live_component.name)

    live_component
    # |> Map.update!(:classes, fn classes ->
    #   Enum.map(classes, &apply_class_variables(&1, scope))
    # end)
    |> Map.update!(:hooks, fn hooks ->
      Enum.map(hooks, &apply_hook_variables(&1, scope))
    end)
    |> Map.update!(:attrs, fn attrs ->
      Enum.map(attrs, &apply_attr_variables(&1, scope))
    end)
    |> Map.update!(:slots, fn slots ->
      Enum.map(slots, &apply_slot_variables(&1, scope))
    end)
    |> Map.update!(:components, fn components ->
      Enum.map(components, &apply_component_variables(&1, scope))
    end)
  end

  defp apply_component_variables(%Pyro.Schema.Component{} = component, scope) do
    scope = Map.put(scope, :component, component.name)

    component
    # |> Map.update!(:classes, fn classes ->
    #   Enum.map(classes, &apply_class_variables(&1, scope))
    # end)
    |> Map.update!(:hooks, fn hooks ->
      Enum.map(hooks, &apply_hook_variables(&1, scope))
    end)
    |> Map.update!(:attrs, fn attrs ->
      Enum.map(attrs, &apply_attr_variables(&1, scope))
    end)
    |> Map.update!(:slots, fn slots ->
      Enum.map(slots, &apply_slot_variables(&1, scope))
    end)
  end

  defp apply_class_variables(%Pyro.Schema.Class{} = class, scope) do
    scope = Map.put(scope, :class, class.name)

    Map.update!(class, :strategies, fn strategies ->
      Enum.map(strategies, &apply_class_strategy_variables(&1, scope))
    end)
  end

  defp apply_class_strategy_variables(%Pyro.Schema.ClassStrategy{} = strategy, scope) do
    scope = Map.put(scope, :strategy, strategy.name)

    strategy =
      maybe_render_template(strategy, :base_class, scope)

    scope = Map.put(scope, :base_class, strategy.base_class.rendered)

    maybe_render_template(strategy, :template, scope)
  end

  defp apply_hook_variables(%Pyro.Schema.Hook{} = hook, scope) do
    scope = Map.put(scope, :hook, hook.name)
    maybe_render_template(hook, :template, scope)
  end

  defp apply_attr_variables(%Pyro.Schema.Attr{} = attr, scope) do
    scope = Map.put(scope, :attr, attr.name)

    attr
    |> maybe_expand_variable(:values, scope)
    |> maybe_expand_variable(:default, scope)
  end

  defp apply_slot_variables(%Pyro.Schema.Slot{} = slot, scope) do
    Map.update!(slot, :attrs, fn attrs -> Enum.map(attrs, &apply_attr_variables(&1, scope)) end)
  end

  defp maybe_render_template(entity, key, scope) do
    Map.update!(entity, key, fn
      %Pyro.Component.Template{} = template ->
        rendered =
          EEx.eval_string(
            template.source,
            [assigns: [{:vars, entity.variables} | Keyword.new(scope)]],
            file: template.file,
            line: template.line,
            indentation: template.indentation,
            trim: true
          )

        Map.put(template, :rendered, rendered)

      value ->
        value
    end)
  end

  defp maybe_expand_variable(entity, key, scope) do
    expanded =
      Map.update!(entity, key, fn
        {:var, key} ->
          vars = entity.variables

          case Map.fetch(vars, key) do
            {:ok, value} ->
              value

            :error ->
              raise KeyError, """
                  Variable #{inspect(key)} was expected by:

                    #{print_path(scope)}

                  But, it was not found in: #{print_map(vars)}

                  #{did_you_mean(vars, key, :variables)}
              """
          end

        {:scope, :variables} ->
          raise KeyError, """
              Scope key :variables was referenced by:

                #{print_path(scope)}

              Variables are not accessible via scope. Instead, use `{:var, :key}`.
          """

        {:scope, key} ->
          case Map.fetch(scope, key) do
            {:ok, value} ->
              value

            :error ->
              raise KeyError, """
                  Scope key #{inspect(key)} was expected by:

                    #{print_path(scope)}

                  #{did_you_mean(scope, key, :scope)}
              """
          end

        old ->
          old
      end)

    # Support linking to other variables/scopes.
    case Map.get(expanded, key) do
      {:var, _} -> maybe_expand_variable(expanded, key, scope)
      {:scope, _} -> maybe_expand_variable(expanded, key, scope)
      _ -> expanded
    end
  end

  @variable_threshold 0.77
  @max_suggestions 3

  defp did_you_mean(variables_or_scope, expected_key, kind) do
    suggestions =
      variables_or_scope
      |> Map.keys()
      |> Enum.reduce([], fn key, acc ->
        dist = String.jaro_distance(Atom.to_string(expected_key), Atom.to_string(key))

        if dist >= @variable_threshold do
          [{dist, key} | acc]
        else
          acc
        end
      end)
      |> Enum.sort(&(elem(&1, 0) >= elem(&2, 0)))
      |> Enum.take(@max_suggestions)

    case suggestions do
      [] ->
        case kind do
          :scope ->
            keys =
              variables_or_scope
              |> Map.keys()
              |> Enum.filter(&(&1 != :variables))
              |> Enum.map_join(", ", &inspect/1)

            "The available scope keys at this level are: #{keys}"

          :variables ->
            "No similar keys were found. You may have forgotten to define it, or import a default template."
        end

      [{_dist, key}] ->
        "Did you mean #{inspect(key)} ?"

      suggestions ->
        [
          "Did you mean one of these similar keys?\n\n"
          | Enum.map(suggestions, &format_suggestion/1)
        ]
    end
  end

  defp format_suggestion({_dist, key}) do
    ["      * ", inspect(key), ?\n]
  end

  defp print_map(map) do
    map
    |> inspect(pretty: true)
    |> String.split("\n")
    |> Enum.join("\n    ")
  end

  defp print_path(scope) do
    [
      {"", Map.get(scope, :module)},
      {"live_component", Map.get(scope, :live_component)},
      {"component", Map.get(scope, :component)},
      {"slot", Map.get(scope, :slot)},
      {"attr", Map.get(scope, :attr)},
      {"class", Map.get(scope, :class)},
      {"strategy", Map.get(scope, :strategy)}
    ]
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Enum.map_join(" -> ", fn {label, name} -> String.trim("#{label} #{inspect(name)}") end)
  end
end
