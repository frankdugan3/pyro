defmodule Pyro.ComponentLibrary.TemplateHelpers do
  @moduledoc false

  def sigil_CSS(str, _opts) do
    str
  end

  def transform_component_render(
        %Pyro.ComponentLibrary.Dsl.Render{args: args, expr: expr} = entity
      ) do
    cond do
      not has_sigil?(expr, :sigil_H) ->
        {:error, "A Pyro component is expected to use ~H in the render function"}

      not has_var?(args, :assigns) ->
        {:error, "~H requires a variable named \"assigns\" to exist and be set to a map"}

      true ->
        {:ok, entity}
    end
  end

  defp has_var?(ast, var_name) when is_atom(var_name) do
    Macro.prewalk(ast, false, fn
      {^var_name, _, context} = node, _acc when is_atom(context) or is_nil(context) ->
        {node, true}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end

  defp has_sigil?(ast, sigil_name) when is_atom(sigil_name) do
    Macro.prewalk(ast, false, fn
      {^sigil_name, _meta, _args} = node, _acc ->
        {node, true}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
  end
end
