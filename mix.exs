defmodule Pyro.MixProject do
  @moduledoc false
  use Mix.Project

  @source_url "https://github.com/frankdugan3/pyro"
  @version "0.3.4"
  @description """
  Component tooling for Phoenix.
  """
  def project do
    [
      app: :pyro,
      version: @version,
      description: @description,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs(),
      test_paths: ["lib"],
      name: "Pyro",
      source_url: @source_url,
      elixirc_paths: ["lib"],
      aliases: aliases(),
      compilers: [:yecc] ++ Mix.compilers(),
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

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
        ~w(lib documentation) ++
          ~w(README* CHANGELOG* LICENSE* mix.exs .formatter.exs)
    ]
  end

  defp groups_for_modules do
    [
      Core: [
        Pyro,
        Pyro.Overrides
      ],
      "Component Tooling": [
        Pyro.Component,
        Pyro.Component.CSS,
        Pyro.LiveComponent,
        Pyro.LiveView,
        Pyro.Component.Helpers
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Code quality tooling
      {:credo, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:doctor, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_check, "~> 0.15", [env: :prod, hex: "ex_check", only: :dev, runtime: false, repo: "hexpm"]},
      {:faker, "~> 0.17", only: [:test, :dev]},
      {:floki, ">= 0.30.0", only: :test},
      {:mix_audit, ">= 0.0.0", only: :dev, runtime: false},
      {:styler, "~> 0.11", only: [:dev, :test], runtime: false},
      # Build tooling
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:git_ops, "~> 2.6", only: :dev},
      # Core dependencies
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix, "~> 1.7"},
      {:jason, "~> 1.4"},
      # These dependencies add optional features if installed
      {:gettext, "~> 0.24", optional: true},
      {:makeup, "~> 1.1", optional: true},
      {:tzdata, "~> 1.1.0", optional: true},
      {:tz_extra, "~> 0.26", optional: true}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "compile", "docs"],
      # until we hit 1.0, we will ensure no major release!
      release: ["git_ops.release --no-major"],
      publish: ["hex.publish"]
    ]
  end
end
