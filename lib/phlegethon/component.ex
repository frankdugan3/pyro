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
      # require Phoenix.Template
      import unquote(__MODULE__)
      import unquote(__MODULE__).Helpers
      alias Phoenix.LiveView.JS

      import unquote(@gettext_backend)
      @gettext_backend unquote(@gettext_backend)
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
          | {:overrides, [module]}
  @spec assign_overridable(map, atom, [assign_overridable_opts]) :: map
  defmacro assign_overridable(assigns, attr, opts \\ []) do
    module = __CALLER__.module
    {component, 1} = __CALLER__.function

    quote bind_quoted: [
            module: module,
            component: component,
            assigns: assigns,
            attr: attr,
            opts: opts
          ] do
            # TODO: For all the validations, see about perhaps hooking into Phoenix's template validator.

      if Keyword.get(opts, :default) do
        raise """
        Cannot override default for "attr :#{attr}"

          - Component: #{module}.#{component}/1
          - Prop: "attr :#{attr}"
          - Reason: "assign_override(:#{attr}, default: #{inspect(Keyword.get(opts, :default))})"

          Overridable defaults *must* be set via override files.
        """
      end

      # TODO: Perhaps support other prop types, or least slot attributes?
      prop =
        with attrs <- module.__components__()[component][:attrs],
             %{opts: opts} = prop <- Enum.find(attrs, &(&1.name == attr)) do
          cond do
            Keyword.get(opts, :default) !== nil ->
              raise """
              Cannot override default for "attr :#{attr}"

                - Component: #{module}.#{component}/1
                - Prop: "attr :#{attr}"
                - Reason: "default: #{inspect(Keyword.get(opts, :default))}"

                If you want to have a default that doesn't require a custom override, remove the default from the prop and instead:

                assign_override(:#{attr}, default: #{inspect(Keyword.get(opts, :default))})
              """

            prop.required == true ->
              raise """
              Cannot override default for "attr :#{attr}"

                - Component: #{module}.#{component}/1
                - Prop: "attr :#{attr}"
                - Reason: "required: true"

                If you want to require an override setting, remove "required: true" from the prop and instead:

                assign_override(:#{attr}, required?: true)
              """

            true ->
              prop
          end
        else
          _ ->
            raise """
            Unable to find prop ":#{attr}" on component "#{module}.#{component}/1".

              Currently only "attr" props are supported.
            """
        end

      # TODO: validate values

      override =
        Keyword.get(opts, :overrides, Phlegethon.Overrides.configured_overrides())
        |> Enum.reduce_while(nil, fn override_module, _ ->
          override_module.overrides()
          |> Map.fetch({{module, component}, attr})
          |> case do
            {:ok, value} -> {:halt, value}
            :error -> {:cont, nil}
          end
        end)
        |> case do
          # TODO: check if it has assigns as it's arg, like Phoenix does.
          override when is_function(override, 1) ->
            override.(assigns)

          override when not is_nil(override) ->
            override

          _ ->
            if Keyword.get(opts, :required?, false) do
              raise """
              No override set for "attr :#{attr}"

                - Component: #{module}.#{component}/1
                - Prop: "attr :#{attr}"
                - Reason: override

                If you want to have a default that doesn't require a custom override, remove the default from the prop and instead:

                assign_override(:#{attr}, default: #{inspect(Keyword.get(opts, :default))})
              """
            else
              nil
            end
        end

      if opts[:class?] do
        assign(
          assigns,
          attr,
          Tails.classes([override, assigns[attr]])
        )
      else
        assign(
          assigns,
          attr,
          case assigns[attr] do
            nil -> override
            value -> value
          end
        )
      end
    end
  end
end
