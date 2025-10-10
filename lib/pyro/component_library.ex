defmodule Pyro.ComponentLibrary do
  @moduledoc """
  > Declaratively build extensible component libraries for Phoenix.

  - For DSL documentation, check out [Component Library DSL](dsl-pyro-blocklibrary.html).
  """
  use Spark.Dsl,
    default_extensions: [extensions: [__MODULE__.Dsl]]

  @doc false
  @impl Spark.Dsl
  def handle_opts(_opts) do
    quote do
      @persist {:component_library?, true}
    end
  end
end
