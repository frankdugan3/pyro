defmodule Pyro.Verifier do
  @moduledoc """
  Shared tooling for verifying Pyro DSL.
  """

  @doc """
  Scaffold a Pyro DSL verifier, importing standard tooling.
  """
  @doc type: :macro
  defmacro __using__(_env) do
    quote do
      use Spark.Dsl.Verifier

      import unquote(__MODULE__)

      alias Spark.Dsl.Verifier
      alias Spark.Error.DslError
    end
  end

  @doc """

  """
  def verify_until_error(result, [], _verifier, _scope) do
    result
  end

  def verify_until_error({:error, error}, _entities, _verifier, _scope) do
    {:error, error}
  end

  def verify_until_error(acc, entities, verifier, scope) when is_list(entities) do
    Enum.reduce_while(entities, acc, fn entity, acc ->
      case verifier.(entity, acc, scope) do
        {:error, error} -> {:halt, {:error, error}}
        result -> {:cont, result}
      end
    end)
  end
end
