defmodule Mix.Tasks.Pyro.Generators.Css do
  @moduledoc false

  use Mix.Tasks.Pyro.Generator

  def generate(module, _opts \\ []) do
    path = Pyro.Info.css_output_path(module)

    if path do
      path = Path.relative_to_cwd(path)
      File.mkdir_p!(path)
      generated_file = Path.join(path, "#{module |> Module.split() |> Enum.join()}.css")
      File.write!(generated_file, gen_module(module))
    end
  end

  defp gen_module(module) do
    classes = Pyro.Info.all_classes_for_strategy(module)
    source_file = Path.relative_to_cwd(module.__info__(:compile)[:source])

    render_module(source_file: source_file, classes: classes)
  end
end
