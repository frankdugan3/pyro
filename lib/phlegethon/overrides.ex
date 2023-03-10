##############################################################################
####    O R I G I N A L    L I C E N S E
##############################################################################

# Copyright 2022 Alembic Pty Ltd.

# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

##############################################################################
####    M O D I F I C A T I O N    N O T I C E
##############################################################################

# Original file: overrides.ex from AshAuthenticationPhoenix (https://github.com/team-alembic/ash_authentication_phoenix/blob/main/lib/ash_authentication_phoenix/overrides.ex)
# Modifications: Changed almost everything, but the basic idea is very much the same.
# Copyright 2023 Frank Dugan III
# Licensed under the MIT license

defmodule Phlegethon.Overrides do
  @moduledoc """
  The overrides system provides out-of-the-box presets while also enabling deep customization of Phlegethon components.

  The `Phlegethon.Overrides.Default` preset is a great example to dig in and see how the override system works. A `Phlegethon.Component` uses [`overridable`](`Phlegethon.Component.overridable/3`) props to reference overrides set in these presets/custom override modules, and loads them as defaults.

  To get started quickly, Phlegethon has a default style that can be used without any customization:

  ```
  config :phlegethon, :overrides,
    [Phlegethon.Overrides.Default, Phlegethon.Overrides.Essential]
  ```

  But you probably want to customize at least a few overrides. To do so, configure your app with:

  ```
  config :phlegethon, :overrides,
    [MyApp.CustomOverrides, Phlegethon.Overrides.Default, Phlegethon.Overrides.Essential]
  ```

  Then, define your overrides in your custom module:

  ```
  defmodule MyApp.CustomOverrides do
    @moduledoc false
    use Phlegethon.Overrides

    override Core, :back do
      set :class, "text-lg font-black"
      set :icon_kind, :outline
      set :icon_name, :arrow_left
    end
  end
  ```

  The overrides will be merged left-to-right, returning the value in the *first* module that sets a given key. So in the above example, the `<Core.back>` component will have an `icon_name` default of `:arrow_left`, since the `MyApp.CustomOverrides` was the first module in the list to provide that key. But the `icon_class` was unspecified in the custom module, so it will return the value from `Phlegethon.Overrides.Default` since it is provided there:

  - You only need to define what you want to override from the other defaults
  - You can use any number of `:overrides` modules, though it is probably best to only use only 2-3 to keep things simple
  - If no modules define the value, it will simply be `nil`
  - If the `overridable` is defined on the component as `required: true`, an error will be raised at compile-time

  > #### Note: {: .warning}
  >
  > If you want to *completely* omit default style, you should still include the `Phlegethon.Overrides.Essential` overrides, because it specially configures essential things components require unrelated to style. Some of them can be safely overridden, but they must be included and do not affect style directly, so you will still have a blank slate for your custom style overrides.
  >
  > ```
  > config :phlegethon, :overrides,
  >   [MyApp.CustomOverrides, Phlegethon.Overrides.Essential]
  > ```
  """

  alias Phlegethon.Overrides

  @doc false
  @spec __using__(any) :: Macro.t()
  defmacro __using__(env) do
    extend_colors = env[:extend_colors]
    global_style = env[:global_style]
    makeup_light = env[:makeup_light]
    makeup_dark = env[:makeup_dark]

    quote do
      require Overrides
      import Overrides, only: :macros
      import Phlegethon.Component.Helpers

      alias Phlegethon.Components.{
        Core,
        Extra,
        SmartDataTable,
        SmartForm
      }

      alias Phlegethon.Info, as: UI
      alias Phoenix.LiveView.JS

      Module.register_attribute(__MODULE__, :override, accumulate: true)
      @component nil
      @extend_colors unquote(extend_colors)
      @global_style unquote(global_style)
      @makeup_light unquote(makeup_light)
      @makeup_dark unquote(makeup_dark)

      @before_compile Overrides
      @doc false
      # Internally used for asset generation.
      @spec extend_colors :: map() | nil
      def extend_colors(), do: @extend_colors

      @doc false
      # Internally used for asset generation.
      @spec global_style :: binary() | nil
      def global_style(), do: @global_style

      @doc false
      # Internally used for asset generation.
      @spec makeup_light :: map() | nil
      def makeup_light(), do: @makeup_light

      @doc false
      # Internally used for asset generation.
      @spec makeup_dark :: map() | nil
      def makeup_dark(), do: @makeup_dark
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

  * A literal value matching the type of the `overridable` prop (compile-time validated)
  * An arity 1 function, which is assigned at runtime and is passes the component's `assigns`

  The function value allows for complex conditionals. For examples of this, please view the source of `Phlegethon.Overrides.Default`.

  > #### Tip: {: .info}
  >
  > Be sure to include the module in the function capture, since this is a macro and will lose the reference otherwise.

  ## Examples

      set :class, "text-lg font-black"
      set :class, &__MODULE__.back_class/1
  """
  @doc type: :macro
  @spec set(atom, any) :: Macro.t()
  defmacro set(selector, value) do
    quote do
      @override {@component, unquote(selector), unquote(value)}
    end
  end

  @doc false
  @spec __before_compile__(any) :: Macro.t()
  defmacro __before_compile__(env) do
    overrides =
      env.module
      |> Module.get_attribute(:override, [])
      |> Map.new(fn {component, selector, value} -> {{component, selector}, value} end)

    makeup =
      if Module.get_attribute(env.module, :makeup_light) ||
           Module.get_attribute(env.module, :makeup_dark) do
        """
        ## Makeup

        """ <>
          case Module.get_attribute(env.module, :makeup_light) do
            style when is_function(style, 0) ->
              module = Function.info(style)[:module]
              name = Function.info(style)[:name]
              "* `makeup_light`: [`#{name}/0`](`#{module}.#{name}/0`)\n"

            _ ->
              ""
          end <>
          case Module.get_attribute(env.module, :makeup_dark) do
            style when is_function(style, 0) ->
              module = Function.info(style)[:module]
              name = Function.info(style)[:name]
              "* `makeup_dark`: [`#{name}/0`](`#{module}.#{name}/0`)\n"

            _ ->
              ""
          end
      else
        ""
      end

    extend_colors =
      case Module.get_attribute(env.module, :extend_colors) do
        %{} = colors ->
          """
          ## Extend Colors

          ```elixir
          #{inspect(colors, pretty: true)}
          ```
          """

        _ ->
          ""
      end

    global_style =
      case Module.get_attribute(env.module, :global_style) do
        style when is_binary(style) ->
          """
          ## Global Style

          ```css
          #{style}
          ```
          """

        _ ->
          ""
      end

    override_docs = """
    - Arity 1 functions are passed all assigns at runtime, allowing complex conditional logic
    - Non-class overrides are assigned first, so class functions have access to all other defaults and passed prop values
    - Classes utilize [Tailwind CSS](https://tailwindcss.com/), and are merged by the component to prevent weird conflicts and bloat

    #{makeup}
    #{extend_colors}
    #{global_style}

    ## Overrides

    #{overrides |> Enum.group_by(fn {{component, _}, _} -> component end) |> Enum.map(fn {{module, component}, overrides} -> """
      - `#{module}.#{component}/1`
      #{Enum.map_join(overrides, "\n", fn {{_, selector}, value} ->
        value = case value do
          value when is_function(value) -> value |> inspect |> String.replace("&", "")
          value -> inspect(value)
        end
        "  - `:#{selector}` `#{value}`"
      end)}
      """ end) |> Enum.join("\n")}
    """

    quote do
      @doc false
      # Internally used for documentation.
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

  @doc false
  # Internally used for asset generation.
  @spec extend_colors :: map() | nil
  def extend_colors do
    configured_overrides()
    |> Enum.reduce_while(nil, fn module, _ ->
      module.extend_colors()
      |> case do
        %{} = value -> {:halt, value}
        nil -> {:cont, nil}
      end
    end)
  end

  @doc false
  # Internally used for asset generation.
  @spec global_style :: binary() | nil
  def global_style do
    configured_overrides()
    |> Enum.reduce_while(nil, fn module, _ ->
      module.global_style()
      |> case do
        value when is_binary(value) -> {:halt, value}
        nil -> {:cont, nil}
      end
    end)
  end

  @doc false
  # Internally used for asset generation.
  @spec makeup_theme :: map()
  def makeup_theme do
    light =
      configured_overrides()
      |> Enum.reduce_while(nil, fn module, _ ->
        module.makeup_light()
        |> case do
          value when is_function(value, 0) -> {:halt, value}
          nil -> {:cont, nil}
        end
      end)

    dark =
      configured_overrides()
      |> Enum.reduce_while(nil, fn module, _ ->
        module.makeup_dark()
        |> case do
          value when is_function(value, 0) -> {:halt, value}
          nil -> {:cont, nil}
        end
      end)

    %{light: light, dark: dark}
  end

  @doc """
  Get am override value for a given component prop.
  """
  @spec override_for({module, atom}, atom) :: any
  def override_for(component, prop) do
    configured_overrides()
    |> Enum.reduce_while(nil, fn module, _ ->
      module.overrides()
      |> Map.fetch({component, prop})
      |> case do
        {:ok, value} -> {:halt, value}
        :error -> {:cont, nil}
      end
    end)
  end

  @doc """
  Get the configured override modules from config.
  """
  @spec configured_overrides() :: [module]
  def configured_overrides() do
    Application.get_env(:phlegethon, :overrides, [Overrides.Default, Overrides.Essential])
  end
end
