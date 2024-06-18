defmodule Pyro.Transformer.MergeSectionVariables do
  @moduledoc false
  use Pyro.Transformer

  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    components_variables =
      dsl_state
      |> Transformer.get_persisted(:component_libraries)
      |> Enum.reduce(%{}, fn module, acc ->
        Map.merge(
          acc,
          Transformer.get_option(module.spark_dsl_config(), [:components], :variables, %{})
        )
      end)
      |> Map.merge(Transformer.get_option(dsl_state, [:components], :variables, %{}))

    dsl_state =
      Transformer.set_option(dsl_state, [:components], :variables, components_variables)

    {:ok, dsl_state}
  end
end
