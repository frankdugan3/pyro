if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Schema do
    @moduledoc false
    def css_class_type do
      {:or, [:string, {:fun, 1}]}
    end

    def inheritable_type(type \\ :string) do
      {:or, [type, {:one_of, [:inherit]}]}
    end

    defmacro __using__(_env) do
      quote do
        import unquote(__MODULE__)

        defdelegate fetch(term, key), to: Map
        defdelegate get(term, key, default), to: Map
        defdelegate get_and_update(term, key, fun), to: Map
      end
    end
  end
end
