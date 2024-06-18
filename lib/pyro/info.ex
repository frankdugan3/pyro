defmodule Pyro.Info do
  @moduledoc "Introspection for pyro."

  # use Spark.InfoGenerator, extension: Pyro.Component, sections: [:components]

  @doc """
  Whether components should be build.
  """
  def build_components?(pyro) do
    Spark.Dsl.Extension.get_persisted(pyro, :build_components?)
  end

  @doc """
  Returns the statically configured component output path.
  """
  def component_output_path(pyro) do
    Spark.Dsl.Extension.get_persisted(pyro, :component_output_path)
  end

  @doc """
  Returns the statically configured JS output path.
  """
  def js_output_path(pyro) do
    Spark.Dsl.Extension.get_persisted(pyro, :js_output_path)
  end

  @doc """
  Returns the statically configured CSS output path.
  """
  def css_output_path(pyro) do
    Spark.Dsl.Extension.get_persisted(pyro, :css_output_path)
  end

  @doc """
  Returns the statically configured CSS strategy.
  """
  def css_strategy(pyro) do
    Spark.Dsl.Extension.get_persisted(pyro, :css_strategy)
  end

  @doc """
  Returns the statically configured CSS normalizer.
  """
  def css_normalizer(pyro) do
    Spark.Dsl.Extension.get_persisted(pyro, :css_normalizer)
  end

  @doc """
  Get the template search paths.
  """
  def template_paths(pyro) do
    Spark.Dsl.Extension.get_opt(pyro, [:components], :template_paths)
  end

  @doc """
  Get all the CSS classes that implement the given CSS strategy for components and live components (defaults to configured).
  """
  def all_classes_for_strategy(pyro, opts \\ []) do
    strategy_name = Keyword.get(opts, :strategy, css_strategy(pyro))

    Enum.reduce(Spark.Dsl.Extension.get_entities(pyro, [:components]), [], fn
      %Pyro.Schema.Component{classes: classes}, acc ->
        reduce_classes(classes, acc, strategy_name)

      %Pyro.Schema.LiveComponent{classes: classes, components: components}, acc ->
        Enum.reduce(
          components,
          reduce_classes(classes, acc, strategy_name)
        )

      _, acc ->
        acc
    end)
  end

  defp reduce_classes(classes, acc, strategy_name) do
    Enum.reduce(classes, acc, fn %Pyro.Schema.Class{} = class, acc ->
      case Enum.find(class.strategies, &(&1.name == strategy_name)) do
        %Pyro.Schema.ClassStrategy{} = strategy ->
          [strategy | acc]

        _ ->
          acc
      end
    end)
  end

  @doc """
  Get all the hooks in components and live components.
  """
  def hooks(pyro) do
    Enum.reduce(Spark.Dsl.Extension.get_entities(pyro, [:components]), [], fn
      %Pyro.Schema.Component{hooks: hooks}, acc ->
        Enum.reduce(hooks, acc, fn hook, acc -> [hook | acc] end)

      %Pyro.Schema.LiveComponent{hooks: hooks, components: components}, acc ->
        Enum.reduce(
          components,
          Enum.reduce(hooks, acc, fn hook, acc -> [hook | acc] end),
          fn %Pyro.Schema.Component{hooks: hooks}, acc ->
            Enum.reduce(hooks, acc, fn hook, acc -> [hook | acc] end)
          end
        )

      _, acc ->
        acc
    end)
  end

  @doc """
  Get a function component by name.
  """
  def component(pyro, name) do
    pyro
    |> Spark.Dsl.Extension.get_entities([:components])
    |> Enum.find(fn
      %Pyro.Schema.Component{name: n} when name == n -> true
      _ -> false
    end)
  end

  @doc """
  List of all function components.
  """
  def components(pyro) do
    pyro
    |> Spark.Dsl.Extension.get_entities([:components])
    |> Enum.filter(fn
      %Pyro.Schema.Component{} -> true
      _ -> false
    end)
  end

  @doc """
  Get a live component by name.
  """
  def live_component(pyro, name) do
    pyro
    |> Spark.Dsl.Extension.get_entities([:components])
    |> Enum.find(fn
      %Pyro.Schema.LiveComponent{name: n} when name == n -> true
      _ -> false
    end)
  end

  @doc """
  List of all live components.
  """
  def live_components(pyro) do
    pyro
    |> Spark.Dsl.Extension.get_entities([:components])
    |> Enum.filter(fn
      %Pyro.Schema.LiveComponent{} -> true
      _ -> false
    end)
  end
end
