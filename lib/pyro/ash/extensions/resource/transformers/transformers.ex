if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Transformers do
    @moduledoc false

    def handle_errors(errors, label, dsl \\ nil) do
      case errors do
        [] ->
          if dsl do
            {:ok, dsl}
          else
            :ok
          end

        [error] ->
          {:error, error}

        errors ->
          list =
            errors
            |> Enum.reverse()
            |> Enum.map_join("\n", &("   - " <> &1.message))

          {:error,
           Spark.Error.DslError.exception(
             path: [:pyro, :data_table],
             message: """
             There are multiple errors with the #{label}:
             #{list}
             """
           )}
      end
    end

    def default_label(%{name: name}), do: default_label(name)

    def default_label(name) when is_atom(name),
      do: default_label(Atom.to_string(name))

    def default_label(name) when is_binary(name),
      do:
        name
        |> String.split("_")
        |> Enum.map_join(" ", &String.capitalize/1)

    defmacro __using__(_env) do
      quote do
        use Spark.Dsl.Transformer
        alias Spark.Dsl.Transformer
        alias Spark.Error.DslError
        import unquote(__MODULE__)
      end
    end
  end
end
