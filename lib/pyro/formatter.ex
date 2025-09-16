defmodule Pyro.Formatter do
  @moduledoc false
  @behaviour Mix.Tasks.Format

  def features(_opts), do: [sigils: [:CSS], extensions: []]

  def format(contents, _opts) do
    c = """
    <<'EOF'
    #{contents}
    EOF
    """

    command = "prettier --parser css #{c}"
    port = Port.open({:spawn, command}, [:binary])

    receive do
      {^port, {:data, d}} -> d
      _ -> contents
    after
      1_000 -> contents
    end
  end
end
