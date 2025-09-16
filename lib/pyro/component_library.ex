defmodule Pyro.ComponentLibrary do
  @moduledoc """
  > Declaratively build extensible component libraries for Phoenix.

  - For DSL documentation, check out [Component Library DSL](dsl-pyro-componentlibrary.html).
  ```
  """
  use Spark.Dsl,
    default_extensions: [extensions: [__MODULE__.Dsl]],
    many_extension_kinds: [:theme_backends],
    extension_kind_types: [theme_backends: {:wrap_list, {:behaviour, Pyro.ThemeBackend}}]

  @doc false
  @impl Spark.Dsl
  def handle_opts(_opts) do
    quote do
      @persist {:component_library?, true}
    end
  end
end
