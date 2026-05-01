defmodule Pyro.Design.JSON.Writer do
  @moduledoc false

  alias Pyro.Design.{Info, Reference, Token}

  def write(design_module) do
    path = Info.json_output(design_module)

    if path do
      json = build(design_module)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, json)
    end

    :ok
  end

  def build(design_module) do
    tokens = Info.tokens(design_module)
    type_map = Info.type_map(design_module)

    tokens
    |> Enum.reduce(%{}, fn {path, token}, acc ->
      put_at_path(acc, path, token_to_dtcg(token, type_map[path]))
    end)
    |> JSON.encode!()
    |> IO.iodata_to_binary()
  end

  defp put_at_path(map, [last], value), do: Map.put(map, Atom.to_string(last), value)

  defp put_at_path(map, [head | tail], value) do
    key = Atom.to_string(head)
    inner = Map.get(map, key, %{})
    Map.put(map, key, put_at_path(inner, tail, value))
  end

  defp token_to_dtcg(%Token{ref: %Reference{} = ref}, _type) do
    %{"$ref" => Reference.to_string(ref)}
  end

  defp token_to_dtcg(%Token{} = token, type) do
    %{}
    |> maybe_put("$type", token.type || type, &Atom.to_string/1)
    |> maybe_put("$value", token.value, &value_to_dtcg/1)
    |> maybe_put("$description", token.description)
    |> maybe_put_deprecated(token.deprecated)
    |> maybe_put_extensions(token.extensions)
  end

  defp maybe_put(map, _key, nil, _fun), do: map
  defp maybe_put(map, key, value, fun), do: Map.put(map, key, fun.(value))
  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_deprecated(map, false), do: map
  defp maybe_put_deprecated(map, value), do: Map.put(map, "$deprecated", value)

  defp maybe_put_extensions(map, ext) when ext == %{}, do: map
  defp maybe_put_extensions(map, ext), do: Map.put(map, "$extensions", ext)

  defp value_to_dtcg(%struct{} = color)
       when struct in [
              Color.SRGB,
              Color.HSL,
              Color.Lab,
              Color.LCHab,
              Color.Oklab,
              Color.Oklch,
              Color.AdobeRGB,
              Color.RGB,
              Color.XYZ
            ] do
    Color.CSS.to_css(color)
  end

  defp value_to_dtcg({scalar, unit}) when is_number(scalar) and is_atom(unit),
    do: %{"value" => scalar, "unit" => Atom.to_string(unit)}

  defp value_to_dtcg({a, b, c, d}) when is_number(a), do: [a, b, c, d]

  defp value_to_dtcg(value) when is_map(value) and not is_struct(value) do
    Map.new(value, fn {k, v} -> {Atom.to_string(k), value_to_dtcg(v)} end)
  end

  defp value_to_dtcg(value) when is_list(value), do: Enum.map(value, &value_to_dtcg/1)

  defp value_to_dtcg(value) when is_atom(value) and not is_nil(value),
    do: Atom.to_string(value)

  defp value_to_dtcg(value), do: value
end
