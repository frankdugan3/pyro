defmodule Pyro.Formatter do
  @moduledoc """
  Mix format plugin that runs Prettier on sigils and file extensions.

  Formats `~JS` sigils inline, and `.css`, `.json`,
  `.html`, `.js`, `.ts`, `.md` files via Prettier.

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
      do_format(contents, opts, prettier, sigil)
    end
  end

  defp do_format(contents, opts, prettier, sigil) do
    parser = parser_for(sigil, opts)
    path = path_for(opts, parser)
    command = build_command(prettier, path, parser, contents)

    port = Port.open({:spawn, command}, [:binary])

    result =
      receive do
        {^port, {:data, data}} -> data
        _ -> contents
      after
        5_000 -> contents
      end

    if sigil, do: ensure_trailing_newline(result), else: result
  end

  defp parser_for(sigil, _opts) when not is_nil(sigil), do: Map.fetch!(@sigil_parsers, sigil)
  defp parser_for(_sigil, opts), do: Map.fetch!(@file_extensions, opts[:extension])

  defp path_for(opts, parser) do
    case opts[:file] do
      nil -> "stdin.#{parser}"
      file -> file_path(file, opts[:line])
    end
  end

  defp file_path(file, line) do
    file
    |> Path.relative_to(Path.dirname(Mix.Project.project_file()))
    |> Kernel.<>(if(line, do: ":#{line}", else: ""))
  end

  defp build_command(prettier, path, parser, contents) do
    heredoc = """
    <<'EOF'
    #{contents}
    EOF
    """

    "#{prettier} --log-level warn --stdin-filepath #{path} --parser #{parser} #{heredoc}"
  end

  defp ensure_trailing_newline(str) do
    if String.ends_with?(str, "\n"), do: str, else: str <> "\n"
  end
end
