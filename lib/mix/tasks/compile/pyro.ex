defmodule Mix.Tasks.Compile.Pyro do
  @moduledoc """
  Generates several asset files to provide Pyro's CSS.

  This automatically runs if you add it to the compilers as described below, but you could also run it manually.

  ## Setup

  Update `mix.exs`, adding the `:pyro` compiler to the list of compilers:

  ```elixir
  def project do
    [
      ...,
      compilers: Mix.compilers() ++ [:pyro]
    ]
  end
  ```

  Then, update `config/dev.exs` to include `:pyro` in the list of `:reloadable_compilers` in your endpoint:

  ```elixir
  config :my_app, MyAppWeb.Endpoint,
    # ...
    reloadable_compilers: [:elixir, :app, :pyro],
  ```
  """

  use Mix.Task

  @doc false
  def run(_args) do
    Mix.Tasks.Compile.Pyro.AssetGenerator.run([])
  end
end
