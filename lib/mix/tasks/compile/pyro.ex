defmodule Mix.Tasks.Compile.Pyro do
  @moduledoc false

  use Mix.Task

  @doc false
  def run(_args) do
    Mix.Tasks.Compile.Pyro.AssetGenerator.run([])
  end
end
