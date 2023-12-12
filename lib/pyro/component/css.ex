defmodule Pyro.Component.CSS do
  @moduledoc """
  Utilities for managing CSS.
  """

  case Application.compile_env(:pyro, :css_class_merger) do
    nil ->
      @doc """
      Merges classes together, providing a few conveniences. It is similar to how `Surface` merges class prop types or `Tails` minus the Tailwind-aware smart merging. This is a key tool for conditional style and reusable components, allow for very granular style overrides.

        - Includes keys of maps or keywords with a `true` value
        - Flattens nested lists
        - Removes duplicate/empty classes
        - Truncate all previous classes with `{:truncate, "new classes"}`
        - Remove specific previous classes with `{:remove, ["mb-2"]}`

      ## Examples

          iex> classes("py-2      px-2")
          "py-2 px-2"

          iex> classes(["py-2", [" px-2"]])
          "px-2 py-2"

          iex> classes(["py-2", ["px-2", "ml-2"], {:truncate, "ml-1"}, :"mr-2"])
          "mr-2 ml-1"

          iex> classes(["py-2", ["px-2", "ml-2"], {:remove, "ml-2"}, :"mr-2"])
          "mr-2 px-2 py-2"

          iex> classes(["py-2", ["px-2", "ml-2"], {:remove, [:"px-2", "asdf", "ml-2"]}, :"mr-2"])
          "mr-2 py-2"

      > #### Note: {: .info}
      >
      > Order is not preserved in the output. This doesn't matter in terms of class precedence, but it does improve merge performance slightly.

      ## Bring Your Own Merger

      You can also override this function with your own by setting the config option, e.g:

      ```
      config :pyro, :css_class_merger, {Tails, :classes, 1}
      # or
      config :pyro, :css_class_merger, &Tails.classes/1
      ```
      """
      def classes(classes) do
        case classes
             |> List.wrap()
             |> Enum.reduce([], &reduce_class/2)
             |> List.flatten()
             |> Enum.uniq()
             |> Enum.join(" ") do
          "" -> nil
          merged -> merged
        end
      end

      def reduce_class({:remove, to_remove}, acc) do
        to_remove = List.wrap(to_remove) |> Enum.map(&to_string/1)

        acc
        |> List.flatten()
        |> Enum.filter(&(&1 not in to_remove))
      end

      def reduce_class({:truncate, class}, _acc) do
        reduce_class(class, [])
      end

      def reduce_class(class, acc) when is_map(class) do
        Enum.reduce(class, acc, &reduce_class/2)
      end

      def reduce_class(class, acc) when is_list(class) do
        Enum.reduce(class, acc, &reduce_class/2)
      end

      def reduce_class({class, true}, acc) do
        reduce_class(class, acc)
      end

      def reduce_class(class, acc) when is_atom(class) do
        reduce_class(Atom.to_string(class), acc)
      end

      def reduce_class(class, acc) when is_binary(class) do
        [
          class
          |> String.split(" ", trim: true)
          |> Enum.uniq()
          | acc
        ]
      end

      def reduce_class(_class, acc), do: acc

    function when is_function(function, 1) ->
      def classes(classes), do: apply(function, [classes])

    {module, function, 1} ->
      defdelegate classes(classes), to: module, as: function
  end
end
