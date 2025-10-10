defmodule Pyro.ComponentLibrary.Dsl.Transformer.BuildComponents do
  @moduledoc false
  use Spark.Dsl.Transformer

  alias Pyro.ComponentLibrary.Dsl.Transformer.ApplyHooks
  alias Spark.Dsl.Transformer

  @impl true
  def after?(module), do: module in [ApplyHooks]

  @impl true
  def transform(dsl) do
    if Transformer.get_persisted(dsl, :component_library?, false) do
      {:ok, dsl}
    else
      {:ok, dsl}
    end
  end
end
