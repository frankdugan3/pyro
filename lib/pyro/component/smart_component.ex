if Code.ensure_loaded?(AshPhoenix) do
  defmodule Pyro.Components.SmartComponent do
    @moduledoc """
    Utilities for building smart components.
    """

    def smart_class(fun, assigns) when is_function(fun, 1), do: fun.(assigns)

    def smart_class(class, _assigns), do: class

    defmacro __using__(_env) do
      quote do
        use Pyro.Component

        import unquote(__MODULE__)
      end
    end
  end
end
