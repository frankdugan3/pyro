defmodule Pyro.Info do
  @moduledoc "Introspection for pyro."

  alias Pyro.ComponentLibrary.Dsl.Component
  alias Pyro.ComponentLibrary.Dsl.LiveComponent
  alias Spark.Dsl.Extension

  @doc """
  Returns the statically configured transformer hook.
  """
  def transformer_hook(pyro) do
    Extension.get_persisted(pyro, :transformer_hook)
  end

  @doc """
  Returns the statically configured component output path.
  """
  def component_output_path(pyro) do
    Extension.get_persisted(pyro, :component_output_path)
  end

  @doc """
  Returns the statically configured CSS output path.
  """
  def css_output_path(pyro) do
    Extension.get_persisted(pyro, :css_output_path)
  end

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
    for %Component{} = component <- Extension.get_entities(pyro, [:components]) do
      component
    end
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
    for %LiveComponent{} = component <- Extension.get_entities(pyro, [:components]) do
      component
    end
  end

  @doc """
  Get the CSS prefix.
  """
  def css_prefix(pyro) do
    pyro |> Extension.get_opt([:css], :prefix, "")
  end
end
