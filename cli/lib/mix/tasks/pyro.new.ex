defmodule Mix.Tasks.Pyro.New do
  @shortdoc "Prints Pyro help information"

  @moduledoc """
  Generates a new project interactively, powered by Pyro templates.
  """

  use Mix.Task

  alias Logger.Backends.Console

  require Logger

  Logger.configure_backend(Console, device: Owl.LiveScreen)

  @impl true
  @doc false

  def run(args) do
    case args do
      [] -> start_wizard()
      _ -> Mix.raise("Invalid arguments, expected: mix pyro.new")
    end
  end

  defp start_wizard do
    Application.ensure_all_started(:owl)

    name = Owl.IO.input(label: "Enter project name:")
    _features = Owl.IO.select(["AshPostgres", "Ecto"], label: "Choose backend:")

    _features =
      Owl.IO.multiselect(["PyroComponents", "AshPyroComponents"], label: "Choose component libs:")

    _features =
      Owl.IO.multiselect(["AshAuthentication", "phx.gen_auth", "[none]"],
        label: "Choose authentication:"
      )

    Owl.Spinner.run(
      fn -> Process.sleep(2_000) end,
      labels: [
        ok: "Project #{name} generated. Thanks for using Pyro! 🚀",
        error: "Failed",
        processing: "Generating files..."
      ]
    )
  end
end
