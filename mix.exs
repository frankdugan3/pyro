defmodule Pyro.MixProject do
  @moduledoc false
  use Mix.Project

  @source_url "https://github.com/frankdugan3/pyro"
  @version "0.3.7"
  @description """
  Compose extensible components for Phoenix.
  """
  @elixir_requirement "~> 1.16"
  def project do
    [
      app: :pyro,
      version: @version,
      description: @description,
      elixir: @elixir_requirement,
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :dev,
      package: package(),
      deps: deps(),
      docs: docs(),
      test_paths: ["test"],
      name: "Pyro",
      source_url: @source_url,
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      compilers: [:yecc] ++ Mix.compilers(),
      dialyzer: [plt_add_apps: [:mix]],
      preferred_cli_env: [
        "test.watch": :test,
        docs: :docs
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      main: "about",
      assets: %{"vhs/output" => "vhs"},
      source_ref: "v#{@version}",
      output: "doc",
      source_url: @source_url,
      before_closing_head_tag: fn type ->
        if type == :html do
          """
          <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
          <script>mermaid.initialize({startOnLoad: true})</script>
          """
        end
      end,
      extra_section: "Guides",
      extras: extras(),
      groups_for_extras: [
        Tutorials: [~r'documentation/tutorials'],
        Reference: [~r'documentation/dsls'],
        Cheatsheets: [~r'documentation/cheatsheets'],
        LiveBooks: [~r'documentation/livebooks']
      ],
      groups_for_modules: [
        Extension: [
          Pyro,
          Pyro.Info
        ],
        "Component Bundles": [
          PyroComponents,
          ~r/(^PyroComponents.Defaults)/
        ],
        "Individual Components": [
          ~r/(^PyroComponents)/
        ],
        "Component Tooling": [
          Pyro.Component.Helpers,
          Pyro.Component.Template
        ],
        Schema: [~r/(^Pyro.Schema)/],
        Transformer: [~r/(^Pyro.Transformer)/],
        Verifier: [~r/(^Pyro.Verifier)/]
      ],
      nest_modules_by_prefix: [
        Pyro.Schema,
        Pyro.Transformer,
        Pyro.Verifier,
        PyroComponents,
        PyroComponents.Defaults
      ],
      groups_for_docs: [
        Components: &(&1[:type] == :component),
        Macros: &(&1[:type] == :macro),
        "DSL Schemas": &(&1[:type] == :dsl_schema)
      ]
    ]
  end

  defp extras do
    ordered =
      [
        {"documentation/about.md", [default: true]},
        "documentation/suite.md",
        "CHANGELOG.md",
        "documentation/tutorials/get-started.md",
        "documentation/tutorials/extending-components.md",
        "documentation/tutorials/class-variants.md"
      ]

    unordered = Path.wildcard("documentation/**/*.{md,cheatmd,livemd}")

    Enum.uniq_by(ordered ++ unordered, fn
      {file, _opts} -> file
      file -> file
    end)
  end

  defp package do
    [
      name: :pyro,
      maintainers: ["Frank Dugan III"],
      licenses: ["MIT"],
      links: %{GitHub: @source_url},
      files: ~w(
        lib documentation
        README* CHANGELOG* LICENSE*
        mix.exs .formatter.exs
        package.json
      )
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
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:doctor, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_check, "~> 0.15",
       [env: :prod, hex: "ex_check", only: :dev, runtime: false, repo: "hexpm"]},
      {:faker, "~> 0.17", only: [:test, :dev]},
      {:floki, ">= 0.30.0", only: :test},
      {:mix_audit, ">= 0.0.0", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.0", only: :test, runtime: false},
      # Build tooling
      {:ex_doc, ">= 0.0.0", only: :docs, runtime: false},
      {:git_ops, "~> 2.6", only: :dev},
      {:file_system, "~> 1.0", only: [:test, :dev]},
      {:makeup, ">= 0.0.0", only: :docs},
      {:makeup_eex, ">= 0.0.0", only: :docs},
      {:makeup_html, ">= 0.0.0", only: :docs},
      {:makeup_elixir, ">= 0.0.0", only: :docs},
      # Core dependencies
      {:igniter, "~> 0.5"},
      {:sourceror, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0.0-rc.0"},
      {:phoenix, "~> 1.7"},
      {:spark, "~> 2.1"},
      # These dependencies add optional features if installed
      {:tzdata, "~> 1.1", optional: true},
      {:tz_extra, "~> 0.26", optional: true}
    ]
  end

  defp aliases do
    [
      build: [
        "spark.formatter",
        "format"
      ],
      setup: ["deps.get", "compile", "docs"],
      # until we hit 1.0, we will ensure no major release!
      release: ["git_ops.release --no-major"],
      publish: ["hex.publish"],
      docs: [
        "spark.cheat_sheets",
        "docs",
        "spark.replace_doc_links"
        # "spark.cheat_sheets_in_search"
      ],
      "spark.cheat_sheets_in_search": "spark.cheat_sheets_in_search --extensions Pyro.Component",
      "spark.formatter":
        "spark.formatter --extensions Pyro.ComponentLibrary.Dsl,Pyro.ThemeBackend.Tailwind",
      "spark.cheat_sheets":
        "spark.cheat_sheets --extensions Pyro.ComponentLibrary.Dsl,Pyro.ThemeBackend.Tailwind",
      "archive.build": &raise_on_archive_build/1
    ]
  end

  defp raise_on_archive_build(_) do
    Mix.raise("""
    You are trying to install "pyro" as an archive, which is not supported. \
    You probably meant to install "pyro_cli" instead
    """)
  end
end
