defmodule Pyro.ComponentLibrary.TemplateHelpers do
  @moduledoc false

  alias Pyro.ComponentLibrary.Dsl.Render

  def sigil_CSS(str, _opts) do
    str
  end

  def transform_component_render(%Render{args: args, expr: expr} = entity) do
    cond do
      not has_var?(args, :assigns) ->
        {:error, "~H requires a variable named \"assigns\" to exist and be set to a map"}

      not has_sigil?(expr, :sigil_H) ->
        {:error, "A Pyro component is expected to use ~H in the render function"}

      not has_attribute?(expr, :"pyro-component") ->
        {:error, "A Pyro component requires the `pyro-component` attrbute"}

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

  defp has_attribute?(ast, attr_name) when is_atom(attr_name) do
    attr_string = Atom.to_string(attr_name)
    sigils = collect_sigil_h(ast)
    sigils != [] and Enum.all?(sigils, &sigil_has_attribute?(&1, attr_string))
  end

  defp collect_sigil_h(ast) do
    Macro.prewalk(ast, [], fn
      {:sigil_H, _meta, [{:<<>>, _string_meta, [content]}, _opts]} = node, acc ->
        {node, [content | acc]}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp sigil_has_attribute?(content, attr_string) when is_binary(content) do
    String.contains?(content, attr_string)
  end
end
