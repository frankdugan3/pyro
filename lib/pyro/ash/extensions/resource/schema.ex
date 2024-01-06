if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Schema do
    @moduledoc false
    def css_class_schema_type do
      {:or, [:string, {:fun, 1}]}
    end

    def inheritable_schema_type(type \\ :string) do
      {:or, [type, {:one_of, [:inherit]}]}
    end

    @type sort ::
            String.t()
            | list({atom, Ash.Sort.sort_order()})
            | list(atom())
            | list(String.t())
            | nil

    def sort_schema_type do
      {:or,
       [
         :string,
         {:list,
          {:tuple,
           [
             :atom,
             {:in, [:asc, :desc, :asc_nils_first, :asc_nils_last, :desc_nils_first, :desc_nils_last]}
           ]}},
         {:list, :atom},
         {:list, :string},
         nil
       ]}
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
