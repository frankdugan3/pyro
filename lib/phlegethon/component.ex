# MODIFIED SOURCE FROM https://github.com/phoenixframework/phoenix_live_view/blob/master/lib/phoenix_component.ex
# TODO: PROPER CITATION/LICENSE!!
defmodule Phlegethon.Component do
  @gettext_backend Application.compile_env!(:phlegethon, :gettext)

  @moduledoc ~S'''
  This is basically the same thing as `Phoenix.Component`, but adds a powerful prop type `overridable/3`, along with a value type of [`:class`](#overridable/3-class-type), which features smart class merging with `Tails`.

  ## Example

  ```elixir
  defmodule MyApp.Components.ExternalLink do
    @moduledoc """
    An external link component.
    """
    use Phlegethon.Component

    overridable :class, :class
    attr :href, :string, required: true
    attr :rest, :global, include: ~w[download hreflang referrerpolicy rel target type]
    slot :inner_block, required: true

    def external_link(assigns) do
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
  > Only added features will be documented here. For everything else, please see the `Phoenix.Component` docs, as they will not be duplicated here.

  *P.S. If anybody from the Phoenix team is thinking this is pretty cool, I'd be happy to discuss a PR to get the `overridable` and `:css` features merged into core, even if it needed to be substantially re-worked. 🙃*
  '''
  defmacro __using__(opts \\ []) do
    conditional =
      if __CALLER__.module != Phoenix.LiveView.Helpers do
        quote do: import(Phoenix.LiveView.Helpers)
      end

    component =
      quote bind_quoted: [opts: opts] do
        import Kernel, except: [def: 2, defp: 2]
        import Phoenix.Component
        require Phoenix.Template
        import Phlegethon.Component
        import Phlegethon.Component.Declarative

        # import Phoenix.Component.Declarative,
        #   only: [def: 2, defp: 2]

        for {prefix_match, value} <- Phlegethon.Component.Declarative.__setup__(__MODULE__, opts) do
          @doc false
          def __global__?(unquote(prefix_match)), do: unquote(value)
        end
      end

    other =
      quote do
        import Phlegethon.Component.Helpers
        alias Phoenix.LiveView.JS

        import unquote(@gettext_backend)
        @gettext_backend unquote(@gettext_backend)
      end

    [conditional, component, other]
  end

  @doc ~S'''
  Declares overridables for a HEEx function component.

  Overridables are similar to attributes, except that they load defaults from the configured `Phlegethon.Overrides` modules. This allows for dead-simple dynamic configuration of components, making them entirely portable and reusable, but with out-of-the-box presets *and* deep customization.

  Overridables also support a special type [`:class`](#overridable/3-class-type), which merges passed props with defaults instead of completely replacing them. This allows for a better balance of global consistency and bespoke exceptions.

  ## Arguments

  - `name` - an atom defining the name of the overridable. Note that overridables cannot define the
  same name as any other overridables, attributes or slots declared for the same component.
  - `type` - an atom defining the type of the overridable.
  - `opts` - a keyword list of options. Defaults to `[]`.

  ### Types

  An overridable is declared by its name, type, and options. The following types are supported:

  | Name            | Description                                                         |
  |-----------------|---------------------------------------------------------------------|
  | `:any`          | any term                                                            |
  | `:class`        | any `Tails` compatible type (binary, lists, boolean keywords)       |
  | `:string`       | any binary string                                                   |
  | `:atom`         | any atom (including `true`, `false`, and `nil`)                     |
  | `:boolean`      | any boolean                                                         |
  | `:integer`      | any integer                                                         |
  | `:float`        | any float                                                           |
  | `:list`         | any list of any arbitrary types                                     |
  | `:map`          | any map of any arbitrary types                                      |
  | A struct module | any module that defines a struct with `defstruct/1`                 |

  ### Class Type

  The `:class` type is a key feature of Phlegethon. The idea is to preserve the delicate balance of global consistency and bespoke exceptions. Defaults are *merged* with the passed prop, eliminating any default classes that conflict with passed prop values. This is far, *far* more useful than completely replacing the defaults with the prop value, as generally only one or two things need to be adjusted.

  Normally, adding in a few extra utility classes is tricky with Tailwind because precedence of one utility over the other is unpredictable, so you end up with needing to do hacks like `font-bold !font-medium` to ensure the later class takes precedence. Not only is this ugly/bad practice, it also adds completely unnecessary bloat to the HTML, and let's be honest: Tailwind bloats that up enough already!

  That's where the Tails integration comes in: The defaults and the passed props get run through `Tails.classes/1`, which filters out values that conflict with each other, outputting only the right-most utility of each kind. Clean, simple, predictable, and efficient.

  > #### Tip: {: .info}
  >
  > If you want to *completely* replace classes with the prop's value instead of merging with the defaults,
  > you can use the `"remove:*"` directive of Tails, which will eliminate any previous classes.
  >
  > ```
  > iex(2)> Tails.classes([["font-black"], "bg-black", "text-lg", "remove:*", "bg-white"])
  > "bg-white"
  > ```
  >
  > ```
  > <.alert class={["remove:*", "bg-yellow-500"]}>
  > ```

  ### Options

  - `:required` - marks an overridable as required. If a caller does not pass the given overridable,
  a compile warning is issued.
  - `:examples` - a non-exhaustive list of values accepted by the overridable, used for documentation
    purposes.
  - `:values` - an exhaustive list of values accepted by the overridables. If a caller passes a literal
    not contained in this list, a compile warning is issued. If an atom is passed, it will be used as a key to load from the component's overrides. This enables making values user-configurable, while still allowing for compile-time validation.
  - `:doc` - documentation for the overridable.

  ## Compile-Time Validations

  LiveView performs some validation of overridables via the `:phoenix_live_view` compiler.
  When overridables are defined, LiveView will warn at compilation time on the caller if:

  - A duplicate `name` is defined between one of the `overridables`/`attributes`/`slots`.
  - A required overridable is not set in one of the configured `Phlegethon.Overrides`.
  - An unknown overridable is given.
  - You specify a literal overridable (such as `value="string"` or `value`, but not `value={expr}`)
  and the type does not match. The following types currently support literal validation:
  `:string`, `:atom`, `:boolean`, `:integer`, `:float`, `:map` and `:list`.
  - You specify a literal overridable and it is not a member of the `:values` list.
  LiveView does not perform any validation at runtime. This means the type information is mostly
  used for documentation and reflection purposes.

  On the side of the LiveView component itself, defining overridables provides the following quality
  of life improvements:

  - Override documentation is generated for the component.
  - Required struct types are annotated and emit compilation warnings. For example, if you specify
  `overridable :user, User, required: true` and then you write `@user.non_valid_field` in your template,
  a warning will be emitted.
  - Calls made to the component are tracked for reflection and validation purposes.

  ## Documentation Generation

  Public function components that define overridables will have their overridable
  types and docs injected into the function's documentation, depending on the
  value of the `@doc` module overridable:

  - if `@doc` is a string, the overridable docs are injected into that string. The optional
  placeholder `[INSERT LVATTRDOCS]` can be used to specify where in the string the docs are
  injected. Otherwise, the docs are appended to the end of the `@doc` string.
  - if `@doc` is unspecified, the overridable docs are used as the default `@doc` string.
  - if `@doc` is `false`, the overridable docs are omitted entirely.

  The injected overridable docs are formatted as a markdown list:

    - `name` (`:type`) (required) - overridable docs. Defaults to `:default`.

  By default, all overridables will have their types and docs injected into the function `@doc`
  string. To hide a specific overridable, you can set the value of `:doc` to `false`.
  '''
  @doc type: :macro
  defmacro overridable(name, type, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      Phlegethon.Component.Declarative.__overridable__!(
        __MODULE__,
        name,
        type,
        opts,
        __ENV__.line,
        __ENV__.file
      )
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
        icon_name: "beaker"
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
end
