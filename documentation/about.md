# About

Pyro is a suite of libraries for building UI in Phoenix.

`Pyro`

- [Component tooling](Pyro.Component) for Phoenix LiveView
- [Customizable](Pyro.Overrides) override system (skins/themes)

[PyroComponents](https://hexdocs.pm/pyro_components)

- A library of [pre-built components](https://hexdocs.pm/pyro_components)
- A set of [preset overrides](https://hexdocs.pm/pyro_components/PyroComponents.Overrides.BEM) to get started quickly while allowing deep customization

[AshPyro](https://hexdocs.pm/ash_pyro)

- An [Ash extensions](https://hexdocs.pm/ash_pyro/AshPyro.Extensions.Resource.html) providing a declarative UI DSL

[AshPyroComponents](https://hexdocs.pm/ash_pyro_components)

- A [library of components](https://hexdocs.pm/ash_pyro_components/AshPyroComponents.html) that automatically render AshPyro DSL with PyroComponents

To install `Pyro` and write your own components, follow the [Get Started](get-started.html) guide. For the other features, please see the "Get Started" guide for the appropriate library instead.

## What "problem" is it solving?

The default model of Phoenix is to generate, then customize. While this does provide great isolation, I have found it pretty tedious to repeatedly make very similar copy & paste boilerplate changes to the generated code every time I create a new Phoenix app. Additionally, some things (like timezone localization) are quite complicated and it would be nice for them to be handled by a library that is updated with future improvements. Copy & pasting boilerplate will lead to maintenance burdens down the road.

The tricky part is handling all the bespoke features in each app while sharing as much as possible. The goal is to provide a wide array of tooling, helpers and components with sane defaults, while allowing very granular overrides and optional libraries. By separating each level of features, you can choose which parts of Pyro to leverage, and which to implement yourself.
