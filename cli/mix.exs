for path <- :code.get_path(),
    Regex.match?(~r/pyro_cli-[\w\.\-]+\/ebin$/, List.to_string(path)) do
  Code.delete_path(path)
end

defmodule Pyro.New.MixProject do
  use Mix.Project

  @source_url "https://github.com/frankdugan3/pyro"
  @version "0.3.7"
  @description """
  Component tooling for Phoenix.
  """
  @elixir_requirement "~> 1.16"

  def project do
    [
      app: :pyro_cli,
      start_permanent: Mix.env() == :prod,
      version: @version,
      description: @description,
      elixir: @elixir_requirement,
      deps: deps(),
      package: [
        maintainers: ["Frank Dugan III"],
        licenses: ["MIT"],
        links: %{GitHub: @source_url},
        files: ~w(lib templates mix.exs README.md)
      ],
      preferred_cli_env: [docs: :docs],
      source_url: @source_url,
      docs: docs(),
      description: """
      Pyro project generator.

      Provides a `mix pyro.new` task to bootstrap a new Elixir application
      from Pyro templates.
      """
    ]
  end

  def application do
    [
      extra_applications: [:eex, :crypto, :owl]
    ]
  end

  def deps do
    [{:owl, "~> 0.9"}, {:ex_doc, "~> 0.24", only: :docs}, {:ucwidth, "~> 0.2"}]
  end

  defp docs do
    [
      source_url_pattern: "#{@source_url}/blob/v#{@version}/cli/%{path}#L%{line}"
    ]
  end
end
