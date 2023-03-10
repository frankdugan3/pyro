defmodule Phlegethon.Component do
  @moduledoc ~S'''
  This is basically the same thing as `Phoenix.Component`, but adds a powerful helper `assign_overridable/2` and some other conveniences.

  ## Example

  ```elixir
  defmodule MyApp.Components.ExternalLink do
    @moduledoc """
    An external link component.
    """
    use Phlegethon.Component

    attr :class, :any
    attr :href, :string, required: true
    attr :rest, :global, include: ~w[download hreflang referrerpolicy rel target type]
    slot :inner_block, required: true

    def external_link(assigns) do
      assigns = assign_overridable(:class, required?: true)
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
  > Please see the `Phoenix.Component` docs, as they will not be duplicated here.
  '''

  @gettext_backend Application.compile_env!(:phlegethon, :gettext)

  defmacro __using__(opts \\ []) do
    quote do
      use Phoenix.Component, Keyword.take(unquote(opts), [:global_prefixes])

      Module.register_attribute(__MODULE__, :__overrides__, accumulate: true)

      @before_compile unquote(__MODULE__)

      import unquote(__MODULE__)
      import unquote(__MODULE__).Helpers
      alias Phoenix.LiveView.JS

      import unquote(@gettext_backend)
      @gettext_backend unquote(@gettext_backend)
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    phlegethon_components =
      env.module
      |> Module.get_attribute(:__overrides__)
      |> Enum.reduce(%{}, fn {component_name, attr_name, opts}, acc ->
        attr =
          with %{attrs: attrs} <-
                 Module.get_attribute(env.module, :__components__)[component_name],
               %{opts: opts} = attr <- Enum.find(attrs, &(&1.name == attr_name)) do
            %{
              attr_opts: opts |> Map.new() |> Map.put(:required, attr.required),
              type: attr.type
            }
          else
            _ ->
              raise """
              Unable to find prop ":#{attr_name}" on component "#{env.module}.#{component_name}/1".

                Currently only "attr" props are supported.
              """
          end

        override =
          opts
          |> Map.new()
          |> Map.merge(attr)

        if override[:attr_opts][:default] do
          raise """
          Cannot override default for "attr :#{attr_name}"

            - Component: #{env.module}.#{component_name}/1
            - Prop: "attr :#{attr_name}"
            - Reason: "assign_override(:#{attr_name}, default: #{inspect(Keyword.get(opts, :default))})"

            Overridable defaults *must* be set via override files, not attribute options.
          """
        end

        if override[:attr_opts][:required] do
          raise """
          Cannot override default for "attr :#{attr_name}"

            - Component: #{env.module}.#{component_name}/1
            - Prop: "attr :#{attr_name}"
            - Reason: "required: true"

            If you want to require an override setting, remove "required: true" from the prop and instead:

            assign_override(:#{attr_name}, required?: true)
          """
        end

        if override[:class?] && override[:type] != :any do
          raise """
          Cannot override default for "attr :#{attr_name}"

            - Component: #{env.module}.#{component_name}/1
            - Prop: "attr :#{attr_name}"
            - Reason: "class?: true", but "type: :#{override[:type]}"

            The class override type is expecting a variety of prop types to pass into Tails.

            You must set the attr type to ":any".
          """
        end

        case Map.get(acc, component_name) do
          nil -> Map.put(acc, component_name, Map.new([{attr_name, override}]))
          component -> Map.put(acc, component_name, Map.put(component, attr_name, override))
        end
      end)

    quote do
      def __phlegethon_components__, do: unquote(Macro.escape(phlegethon_components))
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

  @doc """
  Assign an overridable attribute.

  TODO: Expand on docs.
  """
  @type assign_overridable_opts ::
          {:class?, boolean}
          | {:required?, boolean}
          | {:values, :atom}
  @spec assign_overridable(map, atom, [assign_overridable_opts]) :: map
  defmacro assign_overridable(assigns, attr, opts \\ []) do
    module = __CALLER__.module
    {component, 1} = __CALLER__.function

    Module.put_attribute(module, :__overrides__, {component, attr, opts})

    quote bind_quoted: [
            component: component,
            assigns: assigns,
            attr: attr
          ] do
      opts = __phlegethon_components__()[component][attr]

      # TODO: validate values

      override =
        Map.get(assigns, :overrides, Phlegethon.Overrides.configured_overrides())
        |> Enum.reduce_while(nil, fn override_module, _ ->
          override_module.overrides()
          |> Map.fetch({{__MODULE__, component}, attr})
          |> case do
            {:ok, value} -> {:halt, value}
            :error -> {:cont, nil}
          end
        end)
        |> case do
          {:pass_assigns_to, override} ->
            override = maybe_merge_classes(assigns, attr, override.(assigns), opts)
            assign(assigns, attr, override)

          override when not is_nil(override) ->
            assign(assigns, attr, maybe_merge_classes(assigns, attr, override, opts))

          _ ->
            if opts[:required?] do
              raise """
              No override set for "attr :#{attr}"

                - Component: #{__MODULE__}.#{component}/1
                - Prop: "attr :#{attr}"
                - Reason: override required
              """
            else
              assign(assigns, attr, maybe_merge_classes(assigns, attr, nil, opts))
            end
        end
    end
  end

  @doc false
  def maybe_merge_classes(assigns, attr, override, %{class?: true}) do
    Tails.classes([override, assigns[attr]])
  end

  @doc false
  def maybe_merge_classes(assigns, attr, override, _opts) do
    case assigns[attr] do
      nil -> override
      value -> value
    end
  end
end
