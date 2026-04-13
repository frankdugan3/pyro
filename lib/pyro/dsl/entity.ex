defmodule Pyro.Dsl.Entity do
  @moduledoc false

  defmacro __using__(opts) do
    opts[:schema] || raise "Need to specify entity schema"

    quote do
      @pyro_entity_opts unquote(opts)
      @pyro_entity_schema Keyword.fetch!(@pyro_entity_opts, :schema)
      @pyro_entity_entities Keyword.get(@pyro_entity_opts, :entities, [])

      @moduledoc @moduledoc && @moduledoc <> Spark.Options.docs(@pyro_entity_schema)

      defstruct [
        :__spark_metadata__
        | Keyword.keys(@pyro_entity_schema) ++ Keyword.keys(@pyro_entity_entities)
      ]

      @entities @pyro_entity_entities
                |> Enum.map(fn {key, mods} ->
                  {key, Enum.map(mods, & &1.__entity__())}
                end)

      @entity_opts @pyro_entity_opts
                   |> Keyword.put(:entities, @entities)
                   |> Keyword.put(:target, __MODULE__)
                   |> Keyword.update(:auto_set_fields, [__spark_metadata__: nil], fn fields ->
                     Keyword.put(fields, :__spark_metadata__, nil)
                   end)

      @entity struct!(Spark.Dsl.Entity, @entity_opts)

      @before_compile Pyro.Dsl.Entity

      @doc false
      defdelegate fetch(term, key), to: Map
      @doc false
      defdelegate get(term, key, default), to: Map
      @doc false
      defdelegate get_and_update(term, key, fun), to: Map
      @doc false
      def __entity__, do: @entity
    end
  end

  defmacro __before_compile__(env) do
    schema = Module.get_attribute(env.module, :pyro_entity_schema)
    entities = Module.get_attribute(env.module, :pyro_entity_entities)
    schema_fields = Spark.Options.Docs.schema_specs(schema)

    entity_fields =
      Enum.map(entities, fn {key, mods} ->
        inner =
          case Enum.map(mods, fn mod -> quote(do: unquote(mod).t()) end) do
            [] ->
              quote(do: term())

            [type] ->
              type

            [first | rest] ->
              Enum.reduce(rest, first, fn t, acc -> quote(do: unquote(acc) | unquote(t)) end)
          end

        {key, quote(do: [unquote(inner)])}
      end)

    fields = [
      {:__spark_metadata__, quote(do: Spark.Dsl.Entity.spark_meta())}
      | schema_fields ++ entity_fields
    ]

    quote do
      @type t :: %__MODULE__{unquote_splicing(fields)}
    end
  end
end
