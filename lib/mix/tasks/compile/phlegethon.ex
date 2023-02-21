defmodule Mix.Tasks.Compile.Phlegethon do
  @moduledoc """
  Generates several asset files to provide Phlegethon's CSS.

  This automatically runs if you add it to the compilers as described below, but you could also run it manually.

  ## Setup

  Update `mix.exs`, adding the `:phlegethon` compiler to the list of compilers:

  ```elixir
  def project do
    [
      ...,
      compilers: Mix.compilers() ++ [:phlegethon]
    ]
  end
  ```

  Then, update `config/dev.exs` to include `:phlegethon` in the list of `:reloadable_compilers` in your endpoint:

  ```elixir
  config :my_app, MyAppWeb.Endpoint,
    # ...
    reloadable_compilers: [:elixir, :app, :phlegethon],
  ```
  """

  use Mix.Task

  @doc false
  def run(_args) do
    Mix.Tasks.Compile.Phlegethon.AssetGenerator.run([])
  end
end
