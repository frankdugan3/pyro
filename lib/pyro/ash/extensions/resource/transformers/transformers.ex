if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Transformers do
    @moduledoc false
    import Pyro.Component.Helpers, only: [get_nested: 3]

    alias Spark.Dsl.Transformer

    def filter_actions(dsl, filter) do
      dsl
      |> Transformer.get_entities([:actions])
      |> Enum.filter(filter)
    end

    def get_action(dsl, action) do
      dsl |> Transformer.get_entities([:actions]) |> Enum.find(&(&1.name == action))
    end

    def inherit_pyro_config(dsl, kind, action, option, default \\ nil)

    def inherit_pyro_config(dsl, path, action, option, default) when is_list(path) do
      dsl
      |> Transformer.get_entities(path)
      |> Enum.find(&(&1.name == action))
      |> get_nested([option], default)
    end

    def inherit_pyro_config(dsl, kind, action, option, default) when kind in [:form] do
      inherit_pyro_config(dsl, [:pyro, :form], action, option, default)
    end

    def inherit_pyro_config(dsl, kind, action, option, default) when kind in [:data_table] do
      inherit_pyro_config(dsl, [:pyro, :data_table], action, option, default)
    end

    def inherit_pyro_config(dsl, kind, action, option, default) when kind in [:card, :card_grid] do
      inherit_pyro_config(dsl, [:pyro, :card_grid], action, option, default)
    end

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

    def default_label(name) when is_atom(name), do: default_label(Atom.to_string(name))

    def default_label(name) when is_binary(name),
      do: name |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1)

    defmacro __using__(_env) do
      quote do
        use Spark.Dsl.Transformer

        import unquote(__MODULE__)

        alias Spark.Dsl.Transformer
        alias Spark.Error.DslError
      end
    end
  end
end
