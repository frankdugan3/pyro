defmodule Mix.Tasks.Pyro.Generator do
  @moduledoc false
  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__)

      require EEx

      defdelegate i(term), to: Kernel, as: :inspect

      dir = __MODULE__ |> Module.split() |> List.last() |> Macro.underscore()

      for file <- __DIR__ |> Path.join(dir) |> File.ls!() do
        root_name =
          file
          |> Path.rootname()
          |> Path.rootname()

        name = String.to_atom("render_" <> root_name)
        template = Path.join(__DIR__, "#{dir}/#{file}")

        EEx.function_from_file(:def, name, template, [:assigns], trim: true)
      end
    end
  end
end
