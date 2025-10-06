defmodule Pyro.MixProject do
  @moduledoc false
  use Mix.Project

  alias Pyro.Component.Helpers
  alias Pyro.Component.Template
  alias Pyro.ComponentLibrary.Dsl

  @source_url "https://github.com/frankdugan3/pyro"
  @version "0.3.7"
  @description """
  Compose extensible components for Phoenix.
  """
  @elixir_requirement "~> 1.18"
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
      docs: &docs/0,
      test_paths: ["test"],
      name: "Pyro",
      source_url: @source_url,
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      compilers: [:yecc] ++ Mix.compilers(),
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  def cli do
    [preferred_envs: [docs: :docs]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    Path.wildcard("documentation/**/*.eex")
    |> Enum.each(fn eex_path ->
      output_path = String.replace_suffix(eex_path, ".eex", "")
      File.write!(output_path, EEx.eval_file(eex_path))
    end)

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
          Helpers,
          Template
        ],
        Schema: [~r/(^Pyro.Schema)/],
        Transformer: [~r/(^Pyro.Transformer)/],
        Verifier: [~r/(^Pyro.Verifier)/]
      ],
      nest_modules_by_prefix: [
        Dsl
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
        "documentation/tutorials/get-started.md"
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
        lib
        README* CHANGELOG* LICENSE*
        mix.exs .formatter.exs
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
      {:credo, ">= 0.0.0", only: [:dev, :test, :docs], runtime: false},
      {:quokka, ">= 0.0.0", only: [:dev, :test, :docs], runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:doctor, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_check, "~> 0.15",
       [env: :prod, hex: "ex_check", only: :dev, runtime: false, repo: "hexpm"]},
      {:faker, "~> 0.17", only: [:test, :dev]},
      {:floki, ">= 0.30.0", only: :test},
      {:usage_rules, ">= 0.0.0", only: :dev},
      {:mix_audit, ">= 0.0.0", only: :dev, runtime: false},
      {:mix_test_interactive, ">= 0.0.0", only: :dev, runtime: false},
      # Build tooling
      {:ex_doc, ">= 0.0.0", only: :docs, runtime: false},
      {:git_ops, "~> 2.6", only: :dev},
      {:file_system, "~> 1.0", only: [:test, :dev, :docs]},
      {:makeup, ">= 0.0.0", only: :docs},
      {:makeup_eex, ">= 0.0.0", only: :docs},
      {:makeup_html, ">= 0.0.0", only: :docs},
      {:makeup_elixir, ">= 0.0.0", only: :docs},
      # Core dependencies
      {:igniter, "~> 0.5"},
      {:sourceror, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix, "~> 1.8-rc.0", override: true},
      {:spark, "~> 2.1"},
      # These dependencies add optional features if installed
      {:tzdata, "~> 1.1", optional: true},
      {:tz_extra, "~> 0.26", optional: true}
    ]
  end

  defp aliases do
    [
      usage: """
      usage_rules.sync CLAUDE.md --all \
        --yes --remove-missing \
        --link-style at \
        --link-to-folder deps \
      """,
      update: [
        "deps.update --all",
        "usage"
      ],
      test_and_lint: ["test", "credo"],
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
      "spark.cheat_sheets_in_search":
        "spark.cheat_sheets_in_search --extensions Pyro.ComponentLibrary.Dsl",
      "spark.formatter": "spark.formatter --extensions Pyro.ComponentLibrary.Dsl",
      "spark.cheat_sheets": "spark.cheat_sheets --extensions Pyro.ComponentLibrary.Dsl",
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
