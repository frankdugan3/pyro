defmodule Pyro.Overrides do
  @moduledoc """
  The overrides system provides out-of-the-box presets while also enabling deep customization of Pyro components.

  The `Pyro.Overrides.Default` preset is a great example to dig in and see how the override system works. A `Pyro.Component` flags attrs with `overridable`, then leverages [`assign_overridables/1`](`Pyro.Component.assign_overridables/1`) to reference overrides set in these presets/custom override modules and load them as defaults.

  Pyro defaults to the following overrides:

  ```
  [Pyro.Overrides.Default]
  ```

  But you probably want to customize at least a few overrides. To do so, configure your app with:

  ```
  config :pyro, :overrides,
    [MyApp.CustomOverrides, Pyro.Overrides.Default]
  ```

  Then, define your overrides in your custom module:

  ```
  defmodule MyApp.CustomOverrides do
    @moduledoc false
    use Pyro.Overrides

    override Core, :back do
      set :class, "text-lg font-black"
      set :icon_kind, :outline
      set :icon_name, :arrow_left
    end
  end
  ```

  The overrides will be merged left-to-right, returning the value in the *first* module that sets a given key. So in the above example, the `<Core.back>` component will have an `icon_name` default of `:arrow_left`, since the `MyApp.CustomOverrides` was the first module in the list to provide that key. But the `icon_class` was unspecified in the custom module, so it will return the value from `Pyro.Overrides.Default` since it is provided there:

  - You only need to define what you want to override from the other defaults
  - You can use any number of `:overrides` modules, though it is probably best to only use only 1-3 to keep things simple/efficient
  - If no modules define the value, it will simply be `nil`
  - If [`assign_overridables/1`](`Pyro.Component.assign_overridables/1`) is called on the component with the `required: true` attr option, an error will be raised if no configured overrides define a default
  """

  @doc false
  @spec __using__(any) :: Macro.t()
  defmacro __using__(_env) do
    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__), only: :macros
      import Pyro.Component.Helpers

      alias Pyro.Components.{
        Autocomplete,
        Core,
        SmartDataTable,
        SmartForm
      }

      alias Pyro.Resource.Info, as: UI
      alias Phoenix.LiveView.JS

      Module.register_attribute(__MODULE__, :override, accumulate: true)
      @component nil
      @__pass_assigns_to__ %{}

      @on_definition unquote(__MODULE__)
      @before_compile unquote(__MODULE__)

      @doc false
      # Internally used for validation.
      @spec __pass_assigns_to__ :: map()
      def __pass_assigns_to__(), do: @__pass_assigns_to__
    end
  end

  @doc """
  Define overrides for a specific component.

  You need to specify the module and function name of the component to override.

  ## Examples

      override Core, :back do
        set :class, "text-lg font-black"
      end
  """
  @doc type: :macro
  @spec override(module :: module, component :: atom, do: Macro.t()) :: Macro.t()
  defmacro override(module, component, do: block) do
    quote do
      @component {unquote(module), unquote(component)}
      unquote(block)
    end
  end

  @doc """
  Override a setting within a component.

  Value can be:

  * A literal value matching the type of the prop being overridden
  * A function capture of arity 1 with the argument `passed_assigns`, which is executed at runtime and is passed the component's `assigns`
  * Any other function capture, which will simply be passed along as a literal

  The `passed_assigns` function capture allows for complex conditionals. For examples of this, please view the source of `Pyro.Overrides.Default`.

  > #### Tip: {: .info}
  >
  > Be sure to include the module in the function capture, since this is a macro and will lose the reference otherwise.

  ## Examples

      set :class, "text-lg font-black"
      set :class, &__MODULE__.back_class/1
      # ...
      def back_class(passed_assigns) do
  """
  @doc type: :macro
  @spec set(atom, any) :: Macro.t()
  defmacro set(selector, value) do
    quote do
      @override {@component, unquote(selector), unquote(value)}
    end
  end

  @doc false
  def __on_definition__(env, kind, name, args, _guards, _body) do
    if kind == :def && length(args) == 1 &&
         Enum.find(args, fn {arg, _line, _} -> arg == :passed_assigns end) do
      pass_assigns_to =
        env.module
        |> Module.get_attribute(:__pass_assigns_to__)
        |> Map.put(name, true)

      append =
        "This override is passed component assigns and executed while being assigned at runtime."

      docs =
        case Module.get_attribute(env.module, :doc) do
          false ->
            append

          nil ->
            append

          {_line, docs} ->
            docs <> "\n" <> append
        end

      Module.put_attribute(env.module, :doc, {env.line, docs})
      Module.put_attribute(env.module, :__pass_assigns_to__, pass_assigns_to)
    end

    :ok
  end

  @doc false
  @spec __before_compile__(any) :: Macro.t()
  defmacro __before_compile__(env) do
    overrides =
      env.module
      |> Module.get_attribute(:override, [])
      |> Enum.map(fn
        {component, selector, value} = override when is_function(value, 1) ->
          name =
            value
            |> Function.info()
            |> Keyword.get(:name)

          if Map.get(Module.get_attribute(env.module, :__pass_assigns_to__), name) do
            {component, selector, {:pass_assigns_to, value}}
          else
            override
          end

        override ->
          override
      end)

    env.module
    |> Module.put_attribute(:override, overrides)

    overrides =
      Map.new(overrides, fn {component, selector, value} -> {{component, selector}, value} end)

    override_docs = """
    - Captured functions with arity 1 and the arg named `passed_assigns` are passed component assigns at runtime, allowing complex conditional logic
    - [`assign_overridables/1`](`Pyro.Component.assign_overridables/1`) preserves the definition order of attrs and assigns them in that order, preserving dependency chains
    - Attrs with type `:css_classes` utilize the configured CSS merge utility

    ## Overrides

    #{overrides |> Enum.group_by(fn {{component, _}, _} -> component end) |> Enum.map(fn {{module, component}, overrides} -> """
      - `#{module}.#{component}/1`
      #{Enum.map_join(overrides, "\n", fn {{_, selector}, value} ->
        value = case value do
          {:pass_assigns_to, value} -> value |> inspect |> String.replace("&", "")
          value when is_function(value) -> value |> inspect |> String.replace("&", "")
          value -> inspect(value)
        end
        "  - `:#{selector}` `#{value}`"
      end)}
      """ end) |> Enum.join("\n")}
    """

    quote do
      @moduledoc (case @moduledoc do
                    false ->
                      false

                    nil ->
                      name =
                        __MODULE__
                        |> Module.split()
                        |> List.last()

                      "A #{name} override theme." <> "\n" <> unquote(override_docs)

                    docs ->
                      docs <> "\n" <> unquote(override_docs)
                  end)

      @doc false
      # Internally used to collect overrides.
      def overrides do
        unquote(Macro.escape(overrides))
      end
    end
  end

  @doc """
  Get an override value for a given component prop.
  """
  @spec override_for(module, atom, atom) :: any
  def override_for(module, component, prop) do
    configured_overrides()
    |> Enum.reduce_while(nil, fn override_module, _ ->
      case Code.ensure_compiled(module) do
        {:module, _} ->
          override_module.overrides()
          |> Map.fetch({{module, component}, prop})
          |> case do
            {:ok, value} -> {:halt, value}
            :error -> {:cont, nil}
          end

        {:error, _} ->
          {:cont, nil}
      end
    end)
  end

  @doc """
  Get the configured or default override modules.
  """
  @spec configured_overrides() :: [module]
  def configured_overrides() do
    Application.get_env(:pyro, :overrides, [__MODULE__.Default])
  end
end
