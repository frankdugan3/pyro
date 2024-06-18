defmodule Mix.Tasks.Pyro.Generators.Components do
  @moduledoc false

  use Mix.Tasks.Pyro.Generator

  def generate(module, _opts \\ []) do
    path = Pyro.Info.component_output_path(module)

    if path do
      path = Path.relative_to_cwd(path)
      File.mkdir_p!(path)

      generated_file =
        Path.join(
          path,
          "#{module |> Module.split() |> List.last() |> Macro.underscore()}_components.ex"
        )

      formatted_code =
        module
        |> gen_module()
        |> Code.format_string!(locals_without_parens: [attr: 2, attr: 3, slot: 2, slot: 3])

      File.write!(generated_file, formatted_code)
    end
  end

  def gen_module(module, opts \\ []) do
    embedded? = Keyword.get(opts, :embedded?, false)
    css_strategy = Pyro.Info.css_strategy(module)
    components = Pyro.Info.components(module)
    module_name = append_module_name(module, "Components")
    source_file = Path.relative_to_cwd(module.__info__(:compile)[:source])

    render_module(
      components: components,
      module_name: module_name,
      css_strategy: css_strategy,
      source_file: source_file,
      embedded?: embedded?
    )
  end

  def append_module_name(module, append) do
    module |> Module.split() |> Kernel.++([append]) |> Enum.join(".")
  end
end
