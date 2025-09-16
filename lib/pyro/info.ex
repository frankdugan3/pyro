defmodule Pyro.Info do
  @moduledoc "Introspection for pyro."
  #
  #   # use Spark.InfoGenerator, extension: Pyro.Component, sections: [:components]
  #
  #   @doc """
  #   Whether components should be build.
  #   """
  #   def build_components?(pyro) do
  #     Spark.Dsl.Extension.get_persisted(pyro, :build_components?)
  #   end
  #
  #   @doc """
  #   Returns the statically configured component output path.
  #   """
  #   def component_output_path(pyro) do
  #     Spark.Dsl.Extension.get_persisted(pyro, :component_output_path)
  #   end
  #
  #   @doc """
  #   Returns the statically configured CSS output path.
  #   """
  #   def css_output_path(pyro) do
  #     Spark.Dsl.Extension.get_persisted(pyro, :css_output_path)
  #   end
  #
  #   @doc """
  #   Returns the statically configured CSS strategy.
  #   """
  #   def css_strategy(pyro) do
  #     Spark.Dsl.Extension.get_persisted(pyro, :css_strategy)
  #   end
  #
  #   @doc """
  #   Returns the statically configured CSS normalizer.
  #   """
  #   def css_normalizer(pyro) do
  #     Spark.Dsl.Extension.get_persisted(pyro, :css_normalizer)
  #   end
  #
  #   @doc """
  #   Get the template search paths.
  #   """
  #   def template_paths(pyro) do
  #     Spark.Dsl.Extension.get_opt(pyro, [:components], :template_paths)
  #   end

  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Spark.Dsl.Extension

  @doc """
  Get a function component by name.
  """
  def component(pyro, name) do
    pyro
    |> Extension.get_entities([:components])
    |> Enum.find(fn
      %Component{name: n} when name == n -> true
      _ -> false
    end)
  end

  @doc """
  List of all function components.
  """
  def components(pyro) do
    pyro
    |> Extension.get_entities([:components])
    |> Enum.filter(fn
      %Component{} -> true
      _ -> false
    end)
  end

  @doc """
  Get a live component by name.
  """
  def live_component(pyro, name) do
    pyro
    |> Extension.get_entities([:components])
    |> Enum.find(fn
      %LiveComponent{name: n} when name == n -> true
      _ -> false
    end)
  end

  @doc """
  List of all live components.
  """
  def live_components(pyro) do
    pyro
    |> Extension.get_entities([:components])
    |> Enum.filter(fn
      %LiveComponent{} -> true
      _ -> false
    end)
  end
end
