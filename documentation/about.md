# About

[![hex.pm](https://img.shields.io/hexpm/l/pyro.svg)](https://hex.pm/packages/pyro)
[![hex.pm](https://img.shields.io/hexpm/v/pyro.svg)](https://hex.pm/packages/pyro)
[![hex.pm](https://img.shields.io/hexpm/dt/pyro.svg)](https://hex.pm/packages/pyro)
[![github.com](https://img.shields.io/github/last-commit/frankdugan3/pyro.svg)](https://github.com/frankdugan3/pyro)

> Compose extensible components for Phoenix.

> #### Experimental Library {: .warning}
>
> Pyro is in early development, expect breaking changes.

Pyro is a suite of libraries for building UI in `Phoenix`.

To install Pyro and learn how it works, start at the [Get Started](get-started.html) guide and work your way through the tutorials. They are ordered in a sensible way to explain the various features Pyro offers, and point toward other tools in the Pyro suite when appropriate.

## What "problem" is it solving?

Component libraries generally suffer from a lack of extensibility. Because of this, there tends to be a substantial churn to add features and configuration options that leads to bloat and maintenance pain. On the other hand, minimalist libraries tend to leave a lot of boilerplate work for the consumer. Symptoms like this are why `phx.new` opts to generate a `core_components.ex` file for you customize. It's a great start, but requires a ton of customization to do much of anything.

Pyro aims to provide a middle ground: Components that can be _extended_. It leverages a DSL to describe how a component should be built (it's a superset of `Phoenix.Component`'s DSL), and wraps it with "transformers" that merge component libraries together with your customizations to produce a bespoke component library.

Here's a quick example.

Let's say we found this little button component library:

```elixir
defmodule SimpleButton do
  use Pyro, library?: true

  variables %{
    prefix: "core-",
    colors: ~w[danger warning success info]
  }

  component :button do
    class :class do
      strategy :tailwind  do
        base_class "appearance-none rounded px-4 py-2"
        variants fn assigns ->
          case assigns[:color] do
            "danger" -> "bg-red-500 text-white"
            "warning" -> "bg-yellow-500 text-black"
            "success" -> "bg-green-500 text-black"
            "info" -> "bg-sky-500 text-white"
          end
        end
      end
      strategy :headless_bem do
        base_class ~E"<%= var.prefix %><%= component %>"
        variants [color: ~E"<%= base_class %>--<%= color %>"]
        template headless_bem_template()
      end
    end
    attr :color, :string, values: {:var, :colors}
    slot :inner_block, required: true
    template ~H"""
    <button class={@class}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
```

That should look really familiar if you've written a `Phoenix.Component` before, aside from a few interesting additions. But why bother with creating a DSL to write components that are already declarative?

_Extensibility._ We won't get into the details here, but you may have noticed:

- This button library gave several "strategies" for generating CSS
- There were _variables_ and _templates_.

So let's go ahead and use this component, changing up a few things:

```elixir
defmodule MyAppWeb.CoreComponents do
  use Pyro,
    component_libraries: [SimpleButton]

  # We don't want a prefix
  variables %{prefix: ""}

  component :button do
    class :class do
      # Change that base class
      # Shorthand: base_class can be the second argument
      strategy :tailwind, "appearance-none p-0 m-0"
    end

    # Can even add that extra attribute we need
    attr :icon_name, :string do
      default "arrow-top-right-on-square"
    end

    # We wrap everything in divs for some reason...
    class :wrapper_class "px-2 py-1"

    # Whoah, swap out that template!
    template ~H"""
    <div class={@wrapper_class}>
      <button class={@class}>
        <%= render_slot(@inner_block) %>
        <.icon name={@icon_name} />
      </button>
    </div>
    """
  end
end
```

Did you notice that the DSL is the same both for library author and library consumer? This makes it trivial to contribute back to libraries.

And if you're wondering if the `class` DSL gets turned into an `attr` at compile time, and maybe even the `variants` function is passed `assigns` at runtime, I like the way you think. It does. Variants made easy-peasy!

That's just scratching the surface: There are tons of options and tooling that help you create and use deeply extensible components and libraries.

Intrigued? Go ahead, [Get Started](get-started.html) right now.

## But wait, there's more!

In addition to the tooling for building extensible components, there is a [full suite](suite.html) of libraries that build on the foundation Pyro provides.
