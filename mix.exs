if String.to_integer(System.otp_release()) < 28, do: Mix.raise("Pyro requires OTP 28+")

defmodule Pyro.MixProject do
  @moduledoc false
  use Mix.Project

  @source_url "https://github.com/frankdugan3/pyro"
  @version "0.3.7"
  @description """
  A DTCG-conformant design system DSL for Elixir.
  """
  @elixir_requirement "~> 1.19"

  def project do
    [
      aliases: aliases(),
      app: :pyro,
      compilers: [:yecc] ++ Mix.compilers(),
      consolidate_protocols: Mix.env() not in [:dev, :test],
      deps: deps(),
      description: @description,
      dialyzer: [plt_add_apps: [:mix]],
      docs: &docs/0,
      elixir: @elixir_requirement,
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Pyro",
      package: package(),
      source_url: @source_url,
      start_permanent: Mix.env() == :prod,
      test_paths: ["test"],
      usage_rules: usage_rules(),
      version: @version
    ]
  end

  def cli do
    [preferred_envs: [docs: :docs, "docs.watch": :docs, "test.watch": :test]]
  end

  defp usage_rules do
    [
      file: "CLAUDE.md",
      usage_rules: [{~r/.*/, link: :markdown}]
    ]
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
      source_ref: "v#{@version}",
      output: "doc",
      source_url: @source_url,
      before_closing_head_tag: fn type ->
        if type == :html do
          """
          <meta name="exdoc:autocomplete-limit" content="50">
          <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
          <script>mermaid.initialize({startOnLoad: true})</script>
          """
        end
      end,
      extra_section: "Guides",
      extras: extras(),
      groups_for_extras: [
        Tutorials: [~r'documentation/tutorials'],
        "DSL Reference": [~r'documentation/dsls'],
        Cheatsheets: [~r'documentation/cheatsheets'],
        LiveBooks: [~r'documentation/livebooks']
      ],
      groups_for_modules: [
        Design: [
          ~r/^Pyro\.Design/
        ],
        Tooling: [Pyro.Formatter]
      ],
      groups_for_docs: [
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
        {"documentation/dsls/DSL-Pyro.Design.md",
         search_data: Spark.Docs.search_data_for(Pyro.Design.Dsl)}
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
      maintainers: ["Frank Polasek Dugan III"],
      licenses: ["MIT"],
      links: %{GitHub: @source_url},
      files: ~w(
        lib documentation
        README* CHANGELOG* LICENSE*
        usage_rules.md
        mix.exs .formatter.exs
      )
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      # Code quality tooling
      {:credo, ">= 0.0.0", only: [:dev, :test, :docs], runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:doctor, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_check, ">= 0.0.0", only: :dev, runtime: false},
      {:usage_rules, ">= 0.0.0", only: :dev},
      {:mix_audit, ">= 0.0.0", only: :dev, runtime: false},
      {:mix_test_watch, ">= 0.0.0", only: :test, runtime: false},
      # Build tooling
      {:ex_doc, ">= 0.0.0", only: :docs, runtime: false},
      {:mix_watch_docs, ">= 0.0.0", only: :docs, runtime: false},
      {:makeup, ">= 0.0.0", only: :docs},
      {:makeup_eex, ">= 0.0.0", only: :docs},
      {:makeup_html, ">= 0.0.0", only: :docs},
      {:makeup_elixir, ">= 0.0.0", only: :docs},
      {:git_ops, ">= 0.0.0", only: :dev},
      # Core dependencies
      {:color, "~> 0.6"},
      {:igniter, "~> 0.5"},
      {:spark, "~> 2.1"},
      # Optional integrations
      {:phoenix_live_view, "~> 1.2.0-rc.0", optional: true}
    ]
  end

  @extensions [Pyro.Design.Dsl] |> Enum.map_join(",", &inspect/1)

  defp aliases do
    [
      usage: "usage_rules.sync --yes",
      update: ["deps.update --all", "usage"],
      build: ["spark.formatter", "format"],
      setup: ["deps.get", "compile", "docs"],
      # Until we hit 1.0, ensure no major release!
      release: ["git_ops.release --no-major"],
      publish: ["hex.publish"],
      docs: ["spark.cheat_sheets", "docs", "spark.replace_doc_links"],
      "spark.cheat_sheets_in_search": "spark.cheat_sheets_in_search --extensions #{@extensions}",
      "spark.formatter": "spark.formatter --extensions #{@extensions}",
      "spark.cheat_sheets": "spark.cheat_sheets --extensions #{@extensions}"
    ]
  end
end
