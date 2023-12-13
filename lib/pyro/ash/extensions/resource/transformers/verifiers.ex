if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Verifiers do
    @moduledoc false

    defmacro __using__(_env) do
      quote do
        use Spark.Dsl.Verifier
        alias Spark.Dsl.Verifier
        alias Spark.Error.DslError
        import Pyro.Ash.Extensions.Resource.Transformers
        import unquote(__MODULE__)
      end
    end
  end
end
