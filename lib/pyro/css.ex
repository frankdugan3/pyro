defmodule Pyro.Component.CSS do
  @moduledoc """
  Utilities for managing CSS.
  """

  @doc """
  Merges classes together.
  """
  if Code.ensure_loaded?(Tails) do
    defdelegate classes(classes), to: Tails
  else
    def classes(nil), do: nil
    def classes(""), do: nil
    def classes([]), do: nil
    def classes({:replace, classes}), do: classes(classes)
    def classes(classes) when is_binary(classes), do: classes
    def classes(classes) when is_list(classes), do: merge_classes(classes)

    # CSS class order doesn't matter; do not spend any CPU/memory preserving order
    defp merge_classes([]), do: []

    defp merge_classes(classes) do
      Enum.reduce(classes, [], fn
        nil, acc ->
          acc

        [], acc ->
          acc

        "", acc ->
          acc

        classes, acc when is_list(classes) ->
          merge_sub_classes(classes, acc)

        classes, acc when is_binary(classes) ->
          maybe_pad_class(classes, acc)

        classes, acc when is_atom(classes) ->
          maybe_pad_class(Atom.to_string(classes), acc)

        {:replace, replacement}, _acc ->
          merge_classes(replacement)

        {_, false}, acc ->
          acc

        {classes, true}, acc when is_binary(classes) ->
          maybe_pad_class(classes, acc)

        {classes, true}, acc when is_atom(classes) ->
          maybe_pad_class(Atom.to_string(classes), acc)

        {classes, true}, acc when is_list(classes) ->
          merge_sub_classes(classes, acc)
      end)
    end

    defp merge_sub_classes(classes, acc) do
      case merge_classes(classes) do
        [] -> acc
        classes -> maybe_pad_class(classes, acc)
      end
    end

    defp maybe_pad_class(classes, []), do: classes
    defp maybe_pad_class(classes, acc), do: [[classes, " "], acc]
  end
end
