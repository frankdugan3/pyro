defmodule Pyro.ComponentLibrary.Dsl.Transformer.MergeCSS do
  @moduledoc false
  use Spark.Dsl.Transformer

  alias Spark.Dsl.Extension
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl) do
    if Transformer.get_persisted(dsl, :component_library?, false) do
      {:ok, dsl}
    else
      opts =
        for module <- Transformer.get_persisted(dsl, :component_libraries, []) do
          %{prefix: Extension.get_opt(module, [:css], :prefix)}
        end
        |> Enum.reduce(%{}, &merge_opts(&1, &2))

      opts =
        %{prefix: Transformer.get_option(dsl, [:css], :prefix)}
        |> merge_opts(opts)

      dsl =
        Enum.reduce(opts, dsl, fn {key, value}, dsl ->
          Transformer.set_option(dsl, [:css], key, value)
        end)

      {:ok, dsl}
    end
  end

  defp merge_opts(old_opts, opts) do
    old_opts
    |> maybe_override(:prefix, opts)
  end

  defp maybe_override(old, key, new) do
    Map.update!(old, key, &maybe_override(&1, Map.get(new, key)))
  end

  defp maybe_override(_old, new) when not is_nil(new), do: new
  defp maybe_override(old, _new), do: old
end
