defmodule Pyro.Transformer.CompileComponents do
  @moduledoc false
  use Pyro.Transformer

  @impl true
  def after?(module) do
    module in [Pyro.Transformer.MergeComponents]
  end

  @impl true
  def transform(dsl_state) do
    if not Transformer.get_persisted(dsl_state, :component_library?, false) do
      # components = Pyro.Info.components(dsl_state)
      # live_components = Pyro.Info.live_components(dsl_state)

      dsl_state = dsl_state

      {:ok, dsl_state}
    else
      {:ok, dsl_state}
    end
  end

  # TODO: Use this to transform templates at compile time.
  # expr =
  #   update_sigil_string(expr, :sigil_H, fn template ->
  #     template
  #     |> String.replace("pyro-class", ~S|class={[@base_class, @class]}|)
  #   end)
  #
  # template = Macro.to_string(args) <> Macro.to_string(expr)
  # {:ok, %{entity | expr: expr, template: template}}

  # defp update_sigil_string(ast, sigil_name, fun)
  #      when is_atom(sigil_name) and is_function(fun, 1) do
  #   Macro.postwalk(ast, fn
  #     {^sigil_name, meta, [{:<<>>, bin_meta, parts}, modifiers]} ->
  #       new_parts =
  #         Enum.map(parts, fn
  #           part when is_binary(part) -> fun.(part)
  #           other -> other
  #         end)
  #
  #       {
  #         sigil_name,
  #         meta,
  #         [{:<<>>, bin_meta, new_parts}, modifiers]
  #       }
  #
  #     node ->
  #       node
  #   end)
  # end
end
