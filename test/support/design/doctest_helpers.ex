defmodule Pyro.Design.Test.DoctestHelpers do
  @moduledoc false

  def compile_design!(body) when is_binary(body) do
    module = :"Elixir.Pyro.Design.Doctest#{System.unique_integer([:positive])}"

    source = """
    defmodule #{inspect(module)} do
      use Pyro.Design

      config do
        namespace "doctest"
      end

      design do
        #{body}
      end
    end
    """

    [{mod, _}] = Code.compile_string(source)
    mod
  end

  def token_value(design, path) when is_list(path) do
    Pyro.Design.Info.at(design, path)
  end
end
