defmodule Phlegethon.MixProject do
  @moduledoc false
  use Mix.Project

  @source_url "https://github.com/frankdugan3/phlegethon"
  @version "0.0.0"
  @description """
  An Ash user interface extension with smart Phoenix components.
  """
  def project do
    [
      app: :phlegethon,
      version: @version,
      description: @description,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs(),
      test_paths: ["lib"],
      name: "Phlegethon",
      source_url: @source_url,
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      compilers: Mix.compilers() ++ [:phlegethon]
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
      main: "get-started",
      # Can't use version until we start tagging releases!
      # source_ref: "v#{@version}",
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
      name: :phlegethon,
      maintainers: ["Frank Dugan III"],
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*
      CHANGELOG* documentation),
      links: %{GitHub: @source_url}
    ]
  end

  defp groups_for_modules() do
    [
      Core: [
        Phlegethon,
        Phlegethon.Components,
        Phlegethon.Resource,
        Phlegethon.Info
      ],
      Overrides: [
        Phlegethon.Overrides,
        Phlegethon.Overrides.Default
      ],
      "Resource Extension": [
        Phlegethon.Resource.Form.Action,
        Phlegethon.Resource.Form.ActionType,
        Phlegethon.Resource.Form.Field,
        Phlegethon.Resource.Form.FieldGroup
      ],
      Components: [~r/\.Components\./],
      "Component Tooling": [
        Phlegethon.Component,
        Phlegethon.LiveComponent,
        Phlegethon.LiveView,
        Phlegethon.Component.Overridable,
        Phlegethon.Component.Helpers,
        Phlegethon.Makeup.Style
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    if Mix.env() == :dev do
      [
        mod: {ComponentPreviewer.Application, []},
        extra_applications: [:logger]
      ]
    else
      [
        extra_applications: [:logger]
      ]
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, "~> 2.4"},
      {:ash_phoenix, "~> 1.2"},
      {:bandit, ">= 0.6.4"},
      {:credo, ">= 0.0.0", only: [:dev], runtime: false},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false},
      {:doctor, ">= 0.0.0", only: [:dev], runtime: false},
      {:ex_check, "~> 0.15",
       [env: :prod, hex: "ex_check", only: :dev, runtime: false, repo: "hexpm"]},
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false},
      {:faker, "~> 0.17", only: [:test, :dev]},
      {:file_system, "~> 0.2.1 or ~> 0.3"},
      {:git_ops, "~> 2.5.0", only: [:dev]},
      {:heroicons, "~> 0.5"},
      {:mix_audit, ">= 0.0.0", only: [:dev], runtime: false},
      {:phoenix_live_view, "~> 0.18.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:makeup, "~> 1.1"},
      {:makeup_elixir, "~> 0.16"},
      {:makeup_eex, "~> 0.1.1"},
      {:makeup_js, "~> 0.1.0"},
      {:makeup_json, "~> 0.1.0"},
      {:makeup_html, "~> 0.1.0"},
      {:phoenix, "~> 1.7.0-rc.3", override: true},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:timex, "~> 3.0"},
      {:tzdata, "~> 1.1.0"},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:tails, github: "zachdaniel/tails", branch: "main"}
    ]
  end

  defp aliases do
    [
      setup: [
        "cmd ./setup.sh",
        "deps.get",
        "esbuild.install --if-missing",
        "tailwind.install --if-missing",
        "compile",
        "deps.compile tails --force"
      ],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
