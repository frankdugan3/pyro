defmodule Mix.Tasks.Pyro do
  @shortdoc "Prints Pyro help information"

  @moduledoc """
  Prints Pyro tasks and their information.

      $ mix pyro

  To print the Pyro version, pass `-v` or `--version`, for example:

      $ mix pyro --version

  """

  use Mix.Task

  @version Mix.Project.config()[:version]

  @impl true
  @doc false
  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("Pyro v#{@version}")
  end

  def run(args) do
    case args do
      [] -> general()
      _ -> Mix.raise("Invalid arguments, expected: mix pyro")
    end
  end

  defp general do
    Application.ensure_all_started(:pyro)
    Mix.shell().info("Pyro v#{Application.spec(:pyro, :vsn)}")
    Mix.shell().info("Component tooling for Phoenix.")
    Mix.shell().info("\n## Options\n")
    Mix.shell().info("-v, --version        # Prints Pyro version\n")
    Mix.Tasks.Help.run(["--search", "pyro."])
  end
end
