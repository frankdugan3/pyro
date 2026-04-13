defmodule Pyro.Formatter do
  @moduledoc """
  Mix format plugin that runs Prettier on sigils and file extensions.

  Formats `~JS` sigils inline, and `.css`, `.json`,
  `.html`, `.js`, `.ts`, `.md` files via Prettier.

  Components use `var(--pyro-token-*)` syntax which is valid CSS,
  so no token swapping is needed.

  ## Configuration

      # .formatter.exs
      [
        plugins: [Pyro.Formatter],
        inputs: [
          "*.{heex,ex,exs}",
          "{config,lib,test}/**/*.{heex,ex,exs}",
          "assets/**/*.{css,js,ts}",
          "**/*.{json,md,html}"
        ]
      ]

  ## Options

    * `:prettier_bin` - path to the prettier binary (default: `"prettier"`)
  """

  @behaviour Mix.Tasks.Format

  @sigil_parsers %{
    JS: "acorn"
  }

  @file_extensions %{
    ".css" => "css",
    ".html" => "html",
    ".js" => "acorn",
    ".json" => "json",
    ".md" => "markdown",
    ".ts" => "typescript"
  }

  @impl Mix.Tasks.Format
  def features(_opts) do
    [
      sigils: Map.keys(@sigil_parsers),
      extensions: Map.keys(@file_extensions)
    ]
  end

  @impl Mix.Tasks.Format
  def format(contents, opts) do
    prettier = opts[:prettier_bin] || "prettier"
    sigil = opts[:sigil]

    if sigil && opts[:modifiers] === ~c"noformat" do
      contents
    else
      parser =
        cond do
          sigil -> Map.fetch!(@sigil_parsers, sigil)
          ext = opts[:extension] -> Map.fetch!(@file_extensions, ext)
        end

      path =
        if opts[:file] do
          opts[:file]
          |> Path.relative_to(Path.dirname(Mix.Project.project_file()))
          |> Kernel.<>(if(opts[:line], do: ":#{opts[:line]}", else: ""))
        else
          "stdin.#{parser}"
        end

      heredoc = """
      <<'EOF'
      #{contents}
      EOF
      """

      command =
        "#{prettier} --log-level warn --stdin-filepath #{path} --parser #{parser} #{heredoc}"

      port = Port.open({:spawn, command}, [:binary])

      result =
        receive do
          {^port, {:data, data}} -> data
          _ -> contents
        after
          5_000 -> contents
        end

      if sigil do
        ensure_trailing_newline(result)
      else
        result
      end
    end
  end

  defp ensure_trailing_newline(str) do
    if String.ends_with?(str, "\n"), do: str, else: str <> "\n"
  end
end
