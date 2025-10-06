defmodule Pyro.HEEx.AST.ParseError do
  @moduledoc false
  # quokka:sort
  defexception [
    :message,
    :snippet,
    :source,
    column: 0,
    file: "nofile",
    indentation: 0,
    line: 0,
    source_offset: 0
  ]

  @impl true
  def message(
        %{
          column: column,
          indentation: indentation,
          line: line,
          snippet: nil,
          source: source,
          source_offset: source_offset
        } = exception
      )
      when is_binary(source) do
    line_start = max(line - source_offset - 3, 1)
    line_end = line - source_offset
    digits = line |> Integer.to_string() |> byte_size()
    number_padding = String.duplicate(" ", digits)
    indentation = String.duplicate(" ", indentation)

    source
    |> String.split(["\r\n", "\n"])
    |> Enum.slice((line_start - 1)..(line_end - 1))
    |> Enum.map_reduce(line_start, fn
      expr, line_number when line_number == line_end ->
        arrow = String.duplicate(" ", column - 1) <> "^"

        acc =
          "#{line_number + source_offset} | #{indentation}#{expr}\n #{number_padding}| #{arrow}"

        {acc, line_number + 1}

      expr, line_number ->
        line_number_padding = String.pad_leading("#{line_number + source_offset}", digits)
        {"#{line_number_padding} | #{indentation}#{expr}", line_number + 1}
    end)
    |> case do
      {[], _} ->
        %{exception | snippet: ""}

      {snippet, _} ->
        %{exception | snippet: Enum.join(["\n #{number_padding}|" | snippet], "\n")}
    end
    |> message()
  end

  def message(exception) do
    location =
      exception.file
      |> Path.relative_to_cwd()
      |> Exception.format_file_line_column(exception.line, exception.column)

    "#{location} #{exception.message}#{exception.snippet}"
  end
end
