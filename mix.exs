defmodule Pyro.MixProject do
  @moduledoc false
  use Mix.Project

  @source_url "https://github.com/frankdugan3/pyro"
  @version "0.2.0"
  @description """
  Phoenix components and tooling with (optional) declarative UI for Ash Framework.
  """
  def project do
    [
      app: :pyro,
      version: @version,
      description: @description,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs(),
      test_paths: ["lib"],
      name: "Pyro",
      source_url: @source_url,
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      compilers: Mix.compilers() ++ [:pyro],
      dialyzer: [plt_add_apps: [:ash, :ash_phoenix, :spark, :ecto, :mix]]
    ]
  end

  defp elixirc_paths(:test), do: ["lib"]
  defp elixirc_paths(:dev), do: ["lib", "dev"]
  defp elixirc_paths(_), do: ["lib"]

  defp extras do
    "documentation/**/*.md"
    |> Path.wildcard()
    |> Enum.map(fn path ->
      title =
        path
        |> Path.basename(".md")
        |> String.split(~r/[-_]/)
        |> Enum.map_join(" ", &String.capitalize/1)

      {String.to_atom(path),
       [
         title: title,
         default: title == "Get Started"
       ]}
    end)
  end

  defp groups_for_extras do
    [
      Tutorials: [
        "documentation/tutorials/get-started.md",
        ~r'documentation/tutorials'
      ]
    ]
  end

  defp docs do
    [
      main: "about",
      source_ref: "v#{@version}",
      output: "doc",
      source_url: @source_url,
      extra_section: "GUIDES",
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: groups_for_modules(),
      groups_for_functions: [
        Components: &(&1[:type] == :component),
        Macros: &(&1[:type] == :macro)
      ]
    ]
  end

  defp package do
    [
      name: :pyro,
      maintainers: ["Frank Dugan III"],
      licenses: ["MIT"],
      links: %{GitHub: @source_url},
      files:
        ~w(lib priv documentation) ++
          ~w(README* CHANGELOG* LICENSE* mix.exs package.json .formatter.exs)
    ]
  end

  defp groups_for_modules() do
    [
      Core: [
        Pyro,
        Pyro.Components
      ],
      Overrides: [
        Pyro.Overrides,
        ~r/\.Overrides\./
      ],
      "Ash Resource Extension": [
        Pyro.Resource,
        Pyro.Resource.Info,
        Pyro.Resource.Form.Action,
        Pyro.Resource.Form.ActionType,
        Pyro.Resource.Form.Field,
        Pyro.Resource.Form.FieldGroup
      ],
      Components: [~r/\.Components\./],
      "Component Tooling": [
        Pyro.Component,
        Pyro.Component.CSS,
        Pyro.LiveComponent,
        Pyro.LiveView,
        Pyro.Component.Overridable,
        Pyro.Component.Helpers,
        Pyro.Makeup.Style
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Code quality tooling
      {:credo, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:doctor, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_check, "~> 0.15",
       [env: :prod, hex: "ex_check", only: :dev, runtime: false, repo: "hexpm"]},
      {:faker, "~> 0.17", only: [:test, :dev]},
      {:floki, ">= 0.30.0", only: :test},
      {:mix_audit, ">= 0.0.0", only: :dev, runtime: false},
      # Build tooling
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:git_ops, "~> 2.6", only: :dev},
      # Core dependencies
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.0.18",
       app: false,
       compile: false,
       sparse: "optimized"},
      {:makeup_eex, "~> 0.1.1"},
      {:makeup_elixir, "~> 0.16"},
      {:makeup_html, "~> 0.1.0"},
      {:makeup_js, "~> 0.1.0"},
      {:makeup_json, "~> 0.1.0"},
      {:makeup, "~> 1.1"},
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix, "~> 1.7"},
      # These dependencies add optional features if installed
      {:ash_phoenix, "~> 1.2", optional: true},
      {:ash, "~> 2.4", optional: true},
      {:tails, "~> 0.1.5", optional: true},
      {:timex, "~> 3.0", optional: true},
      {:tzdata, "~> 1.1.0", optional: true}
    ]
  end

  defp aliases do
    [
      build: [
        "spark.formatter --extensions Pyro.Resource",
        "format"
      ],
      setup: [
        "deps.get",
        "compile",
        "docs"
      ]
    ]
  end
end
