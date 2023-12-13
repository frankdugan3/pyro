if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Schema do
    def css_class_type() do
      :any
    end

    def inheritable_type(type \\ :string) do
      {:or, [type, {:one_of, [:inherit]}]}
    end

    defmacro __using__(_env) do
      quote do
        import unquote(__MODULE__)
      end
    end
  end
end
