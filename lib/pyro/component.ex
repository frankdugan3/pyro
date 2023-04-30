defmodule Pyro.Component do
  @moduledoc ~S'''
  This is basically the same thing as `Phoenix.Component`, but Pyro extends the `attr/3` macro with:

  * `:tails_classes` type
  * `:overridable` flag
  * `:values` supports an atom value (override key)

  Pyro also provides `assign_overridables/1`, which automatically assigns all flagged `overridable` attrs with defautls from `Pyro.Overrides`

  ## Example

  ```elixir
  defmodule MyApp.Components.ExternalLink do
    @moduledoc """
    An external link component.
    """
    use Pyro.Component

    attr :overrides, :list, default: nil, doc: @overrides_attr_doc
    attr :class, :tails_classes, overridable: true, required: true
    attr :href, :string, required: true
    attr :rest, :global, include: ~w[download hreflang referrerpolicy rel target type]
    slot :inner_block, required: true

    def external_link(assigns) do
      assigns = assign_overridables(assigns)
      ~H"""
      <a class={@class} href={@href}} {@rest}>
        <%= render_slot(@inner_block) %>
      </a>
      """
    end
  end
  ```

  > #### Note: {: .info}
  >
  > Only additional features will be documented here. Please see the `Phoenix.Component` docs for the rest, as they will not be duplicated here.
  '''

  @overrides_attr_doc "Manually set the overrides for this component (instead of config/default)"

  defmacro __using__(opts \\ []) do
    conditional =
      if __CALLER__.module != Phoenix.LiveView.Helpers do
        quote do: import(Phoenix.LiveView.Helpers)
      end

    component =
      quote bind_quoted: [opts: opts] do
        import Kernel, except: [def: 2, defp: 2]
        import Phoenix.Component, except: [attr: 2, attr: 3]
        import Phoenix.Component.Declarative
        require Phoenix.Template

        for {prefix_match, value} <-
              Phoenix.Component.Declarative.__setup__(
                __MODULE__,
                Keyword.take(opts, [:global_prefixes])
              ) do
          @doc false
          def __global__?(unquote(prefix_match)), do: unquote(value)
        end
      end

    pyro =
      quote do
        @overrides_attr_doc unquote(@overrides_attr_doc)

        Module.register_attribute(__MODULE__, :__overridable_attrs__, accumulate: true)
        Module.register_attribute(__MODULE__, :__assign_overridables_calls__, accumulate: true)
        Module.put_attribute(__MODULE__, :__overridable_components__, %{})

        import unquote(__MODULE__)
        import unquote(__MODULE__).Helpers
        alias Phoenix.LiveView.JS

        @on_definition unquote(__MODULE__)
        @before_compile unquote(__MODULE__)

        Module.delete_attribute(__MODULE__, :__overridable_attrs__)
        Module.delete_attribute(__MODULE__, :__assign_overridables_calls__)
      end

    [conditional, component, pyro]
  end

  @doc """
  There are only a few things added to `Phoenix.Component.attr/3` by Pyro:

  * `:tails_classes` type
    * merges overridable defaults with passed prop values via `Tails`
    * prevents weird precedence conflicts
    * less bloated HTML
  * `:overridable` flag (marks attribute to be overridden by `Pyro.Overrides`)
  * `:values` supports an atom value (override key, loaded by `Pyro.Overrides`)

  There are compile time checks to ensure the following, but of note:

  * Attrs flagged as `overridable` cannot have a `default` - That's what overrides are for! 🚀
  * If flagged as `overridable` and `required`, a runtime exception will be raised if no configured overrides provide a default
  * If any attrs are flagged as overridable
    * The first attribute must be:

    ```
    attr :overrides, :list, default: nil, doc: @overrides_attr_doc
    ```

    * `assign_overridables/1` must be called

  Everything else is handled by `Phoenix.Component.attr/3`, so please consult those docs for the rest.
  """
  defmacro attr(name, type, opts \\ []) do
    type =
      if Macro.quoted_literal?(type) do
        Macro.prewalk(type, &expand_alias(&1, __CALLER__))
      else
        type
      end

    if type == :tails_classes && !opts[:overridable] do
      invalid_overridable_attr_option!(
        __CALLER__,
        name,
        ":tails_classes type is only available for overridable props",
        "attr #{inspect(name)}, :tails_classes, overridable: true"
      )
    end

    if opts[:overridable] && opts[:default] do
      invalid_overridable_attr_option!(
        __CALLER__,
        name,
        "attr #{inspect(name)}, default: #{inspect(opts[:default])}",
        """
        remove the default from the attr options.

          Overridable defaults *must* be set via override files, not attribute options.

        """
      )
    end

    # Append overridable info to docs
    opts =
      if opts[:overridable] do
        Keyword.put(
          opts,
          :doc,
          [
            opts[:doc],
            "(#{["overridable", if(type == :tails_classes, do: "`#{inspect(type)}`"), if(opts[:required], do: "required")] |> Enum.filter(& &1) |> Enum.join(", ")})"
          ]
          |> Enum.filter(& &1)
          |> Enum.join(" ")
        )
      else
        opts
      end

    phoenix_opts =
      if opts[:overridable] do
        drops =
          case opts[:values] do
            values when not is_nil(values) and is_atom(values) ->
              [:values]

            _ ->
              []
          end ++ [:overridable, :required]

        Keyword.drop(opts, drops)
      else
        opts
      end

    # Phoenix doesn't support the `:tails_classes` type natively
    phoenix_type =
      case type do
        :tails_classes -> :any
        type -> type
      end

    quote bind_quoted: [
            name: name,
            type: type,
            phoenix_type: phoenix_type,
            opts: opts,
            phoenix_opts: phoenix_opts
          ] do
      Pyro.Component.__overridable_attr__!(
        __MODULE__,
        name,
        type,
        opts,
        __ENV__.line,
        __ENV__.file
      )

      Phoenix.Component.Declarative.__attr__!(
        __MODULE__,
        name,
        phoenix_type,
        phoenix_opts,
        __ENV__.line,
        __ENV__.file
      )
    end
  end

  @doc """
  This macro automatically assigns all the overridable attrs, and handles merging classes for `:tails_classes` type attrs.

  It *must* be called once in any component that contains overridable attrs.

  ## Example

  ```
  def external_link(assigns) do
      assigns = assign_overridables(assigns)
  ```
  """
  @spec assign_overridables(map) :: map
  defmacro assign_overridables(assigns) do
    module = __CALLER__.module
    {component_name, 1} = __CALLER__.function

    # TODO: Check that it isn't already defined, implying it got called twice in the same component
    Module.put_attribute(module, :__assign_overridables_calls__, component_name)

    quote bind_quoted: [assigns: assigns, module: module, component_name: component_name] do
      __overridable_components__()[component_name][:overridable_attrs]
      |> Enum.reduce(assigns, fn %{name: name, required: required} = opts, assigns ->
        # TODO: Validate values at runtime; load overridable values if atom instead of list.

        override =
          Map.get(assigns, :overrides) ||
            Pyro.Overrides.configured_overrides()
            |> Enum.reduce_while(nil, fn override_module, _ ->
              override_module.overrides()
              |> Map.fetch({{__MODULE__, component_name}, name})
              |> case do
                {:ok, value} -> {:halt, value}
                :error -> {:cont, nil}
              end
            end)
            |> case do
              {:pass_assigns_to, override} ->
                override = maybe_merge_classes(assigns, name, override.(assigns), opts)
                assign(assigns, name, override)

              override when not is_nil(override) ->
                assign(assigns, name, maybe_merge_classes(assigns, name, override, opts))

              _ ->
                if required do
                  raise """
                  No override set for "attr #{inspect(name)}"

                    * Component: #{__MODULE__}.#{component_name}/1
                    * Prop: "attr #{inspect(name)}"
                    * Problem: override is required to be set
                  """
                else
                  assign(assigns, name, maybe_merge_classes(assigns, name, nil, opts))
                end
            end
      end)
    end
  end

  @doc ~S'''
  Encode a flash message as a JSON binary with extra metadata options. This is necessary because Phoenix only allows binary messages, but many flash messages would be vastly improved by bespoke presentation.

  This allows you to override the defaults for:

  * `:title` - The title above the message
  * `:close` - Auto-close the flash after `:ttl`
  * `:ttl` - The time-to-live in milliseconds
  * `:icon_name` - Name of the icon displayed in the title
  * `:style_for_kind` - Override which kind of style this flash should have

  ## Examples

  ```elixir
  socket
  |> put_flash(
      "success",
      encode_flash(
        """
        This flash closes when it *wants to*.
        And has a custom title and icon.
        """,
        title: "TOTALLY CUSTOM",
        ttl: 6_000,
        icon_name: "hero-beaker"
      )
    )
  ```
  '''
  @type encode_flash_opts ::
          {:ttl, pos_integer}
          | {:title, binary}
          | {:icon_name, binary}
          | {:close, boolean}
          | {:style_for_kind, binary}
  @spec encode_flash(binary, [encode_flash_opts]) :: binary()
  def encode_flash(message, opts) do
    Jason.encode!(%{
      "ttl" => opts[:ttl],
      "title" => opts[:title],
      "icon_name" => opts[:icon_name],
      "close" => opts[:close],
      "style_for_kind" => opts[:style_for_kind],
      "message" => message
    })
  end

  @doc false
  # Internal tooling to merge classes at runtime
  def maybe_merge_classes(assigns, attr, override, %{class?: true}) do
    Tails.classes([override, assigns[attr]])
  end

  def maybe_merge_classes(assigns, attr, override, %{type: :tails_classes}) do
    Tails.classes([override, assigns[attr]])
  end

  def maybe_merge_classes(assigns, attr, override, _opts) do
    case assigns[attr] do
      nil -> override
      value -> value
    end
  end

  @doc false
  def __on_definition__(env, kind, name, args, _guards, _body) do
    if length(args) == 1 && not String.starts_with?(to_string(name), "__") &&
         Enum.find(args, fn {arg, _line, _} -> arg == :assigns end) do
      # Get list of attribute line numbers for this component
      attr_lines =
        Module.get_attribute(env.module, :__components__)[name][:attrs]
        |> Enum.map(& &1.line)

      # Only include overrides that have the same line
      attrs =
        Module.get_attribute(env.module, :__overridable_attrs__)
        |> Enum.filter(&(&1.line in attr_lines))
        # We need to preserve definition order
        |> Enum.reverse()

      overrides = Enum.filter(attrs, & &1.overridable)

      first_attr = List.first(attrs)

      # Automatically mark the doc type as a component
      Module.put_attribute(env.module, :doc, {first_attr.line - 1, type: :component})

      unless Enum.empty?(overrides) do
        case first_attr do
          %{name: :overrides, type: :list, opts: [default: nil, doc: _]} ->
            :ok

          attr ->
            raise CompileError,
              line: attr.line,
              file: attr.file,
              description: """


              Pyro.Component - Missing :overrides Prop

                * Prop: attr #{inspect(attr.name)}
                * Problem: The first prop of the component must be :overrides
                * Solution:

                  attr :overrides, :list, default: nil, doc: @overrides_attr_doc
                  attr #{inspect(attr.name)} # ...
                  # ... other props
                  #{kind} #{name} (assigns) do
              """
        end

        components = Module.get_attribute(env.module, :__overridable_components__)

        if Map.get(components, name) do
          raise """
          Pyro.Component: Component #{module_label(env.module)}.#{name}/1 already defined.
          This is probably a Pyro bug, as this should never be possible.
          """
        end

        Module.put_attribute(
          env.module,
          :__overridable_components__,
          Map.put(components, name, %{kind: kind, overridable_attrs: overrides})
        )
      else
        :ok
      end

      :ok
    else
      :ok
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    assign_overridable_calls = Module.get_attribute(env.module, :__assign_overridables_calls__)

    overridable_components =
      env.module
      |> Module.get_attribute(:__overridable_components__)

    overridable_components
    |> Enum.each(fn {name, opts} ->
      unless name in assign_overridable_calls do
        raise CompileError,
          file: env.file,
          description: """


          Pyro.Component - Missing Call to assign_overridables/1

            * Component: #{module_label(env.module)}.#{name}/1
            * Problem: assign_overridables/1 must be called by components with overridable props
            * Solution:

              #{opts[:kind]} #{name} (assigns) do
                assigns = assign_overridables(assigns)
          """
      end
    end)

    override_docs =
      if overridable_components && overridable_components != %{} do
        """
        ## Overridable Component Attributes

        You can customize the components in this module by [configuring overrides](`Pyro.Overrides`).

        The components in this module support the following overridable attributes:

        #{overridable_components |> Enum.map(fn {component, %{overridable_attrs: attrs}} -> """
          - `#{component}/1`
          #{Enum.map_join(attrs, "\n", fn %{name: name, type: type, required: required} -> "  - `#{inspect(name)}` `#{inspect(type)}`" <> if required, do: " (required)", else: "" end)}
          """ end) |> Enum.join("\n")}
        """
      else
        ""
      end

    quote do
      @moduledoc (case @moduledoc do
                    false ->
                      false

                    nil ->
                      name =
                        __MODULE__
                        |> Module.split()
                        |> List.last()

                      unquote(override_docs)

                    docs ->
                      docs <> "\n" <> unquote(override_docs)
                  end)

      def __overridable_components__() do
        @__overridable_components__
      end
    end
  end

  @doc false
  def __overridable_attr__!(module, name, type, opts, line, file)
      when is_atom(name) and is_list(opts) do
    {overridable, opts} = Keyword.pop(opts, :overridable, false)
    {required, opts} = Keyword.pop(opts, :required, false)

    overridable = %{
      name: name,
      overridable: overridable,
      type: type,
      required: required,
      opts: opts,
      file: file,
      line: line
    }

    Module.put_attribute(
      module,
      :__overridable_attrs__,
      overridable
    )

    :ok
  end

  defp expand_alias({:__aliases__, _, _} = alias, env),
    do: Macro.expand(alias, %{env | function: {:__attr__, 3}})

  defp expand_alias(other, _env), do: other

  defp invalid_overridable_attr_option!(env, attr_name, problem, solution) do
    raise CompileError,
      line: env.line,
      file: env.file,
      description: """


      Pyro.Component - Invalid Overridable Option

        * Prop: attr #{inspect(attr_name)}
        * Problem: #{problem}
        * Solution: #{solution}
      """
  end

  @spec module_label(module) :: String.t()
  defp module_label(module),
    do:
      module
      |> Module.split()
      |> Enum.join(".")
end
