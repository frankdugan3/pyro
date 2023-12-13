if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Schema do
    def css_class_type() do
      :any
    end

    defmacro __using__(_env) do
      quote do
        import unquote(__MODULE__)
      end
    end
  end
end
