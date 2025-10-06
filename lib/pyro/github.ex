defmodule Pyro.GitHub do
  @moduledoc false

  # Create pre-filled issues to be used in errors.
  @spec new_issue_link(title :: String.t(), body :: String.t(), opts :: keyword()) :: String.t()
  def new_issue_link(title, body, opts \\ []) do
    repo = Keyword.get(opts, :repo, "pyro")
    owner = Keyword.get(opts, :owner, "frankdugan3")
    template = Keyword.get(opts, :template, "bug-report.md")
    base_url = "https://github.com/#{owner}/#{repo}/issues/new"
    base_params = [{"title", title}, {"body", body}]

    params =
      case template do
        nil -> base_params
        template -> [{"template", template} | base_params]
      end

    query_string =
      params
      |> Enum.map_join("&", fn {key, value} -> "#{key}=#{URI.encode(value)}" end)

    "#{base_url}?#{query_string}"
  end

  def function_from_env(env) do
    module =
      env.module
      |> Module.split()
      |> Enum.join(".")

    fun = elem(env.function, 0)
    arity = elem(env.function, 1)
    "#{module}.#{fun}/#{arity}"
  end
end
