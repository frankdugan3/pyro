![Logo](https://github.com/frankdugan3/pyro/blob/main/logos/logo.png?raw=true)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Hex version badge](https://img.shields.io/hexpm/v/pyro.svg)](https://hex.pm/packages/pyro)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/pyro)

# Pyro

> ️⚠️ THIS LIBRARY IS HIGHLY EXPERIMENTAL!! ⚠️
>
> 🔥 THERE WILL BE BREAKING CHANGES!! 🔥

Phoenix components and tooling with (optional) declarative UI for Ash Framework.

Pyro's documentation is housed on [hexdocs](https://hexdocs.pm/pyro), which includes detailed [installation instructions](https://hexdocs.pm/pyro/get-started.html) and other guides.

## Dependencies

```elixir
def deps do
  [
    {:pyro, "~> 0.0.1"},
    {:ash_phoenix, "~> 1.2"}, # Optional: Ash integration
    {:ash, "~> 2.8"}, # Optional: Ash integration
  ]
end
```

## What is Pyro?

1. [Component tooling](https://hexdocs.pm/pyro/Pyro.Component.html) for Phoenix LiveView
2. A library of pre-built components that are [api-compatible replacements](https://hexdocs.pm/pyro/Pyro.Components.Core.html) of `core_components.ex` plus [additional components](https://hexdocs.pm/pyro/Pyro.Components.Extra.html) to cover most common UI requirements
3. An [Ash extension](https://hexdocs.pm/pyro/Pyro.Components.Extra.html) providing a declarative UI DSL
4. A library of (optional) "smart components" that leverage 1-3 to automatically render [forms](https://hexdocs.pm/pyro/Pyro.Components.SmartForm.html)/[data tables](https://hexdocs.pm/pyro/Pyro.Components.SmartDataTable.html)/etc. for Ash resources
5. A set of [default](https://hexdocs.pm/pyro/Pyro.Overrides.Default.html), [customizable](https://hexdocs.pm/pyro/Pyro.Overrides.html) themes for all the above

For more details, check out the [About](https://hexdocs.pm/pyro/about.html) page.

## Roadmap

- [ ] Core components
  - [x] [`back/1`](https://hexdocs.pm/pyro/Pyro.Components.Core.html#back/1)
  - [x] [`button/1`](https://hexdocs.pm/pyro/Pyro.Components.Core.html#button/1)
  - [x] [`error/1`](https://hexdocs.pm/pyro/Pyro.Components.Core.html#error/1)
  - [x] [`flash/1`](https://hexdocs.pm/pyro/Pyro.Components.Core.html#flash/1)
  - [x] [`flash_group/1`](https://hexdocs.pm/pyro/Pyro.Components.Core.html#flash_group/1)
  - [x] [`header/1`](https://hexdocs.pm/pyro/Pyro.Components.Core.html#header/1)
  - [x] [`icon/1`](https://hexdocs.pm/pyro/Pyro.Components.Core.html#icon/1)
  - [x] [`input/1`](https://hexdocs.pm/pyro/Pyro.Components.Core.html#input/1)
  - [x] [`label/1`](https://hexdocs.pm/pyro/Pyro.Components.Core.html#label/1)
  - [x] [`list/1`](https://hexdocs.pm/pyro/Pyro.Components.Core.html#list/1)
  - [x] [`simple_form/1`](https://hexdocs.pm/pyro/Pyro.Components.Core.html#simple_form/1)
  - [ ] [`table/1`](https://hexdocs.pm/pyro/Pyro.Components.Core.html#table/1)
  - [ ] [`modal/1`](https://hexdocs.pm/pyro/Pyro.Components.Core.html#modal/1)
- [ ] Extra components
  - [x] [`a/1`](https://hexdocs.pm/pyro/Pyro.Components.Extra.html#a/1)
  - [x] [`code/1`](https://hexdocs.pm/pyro/Pyro.Components.Extra.html#code/1)
  - [x] [`copy_to_clipboard/1`](https://hexdocs.pm/pyro/Pyro.Components.Extra.html#copy_to_clipboard/1)
  - [x] [`nav_link/1`](https://hexdocs.pm/pyro/Pyro.Components.Extra.html#nav_link/1)
  - [x] [`progress/1`](https://hexdocs.pm/pyro/Pyro.Components.Extra.html#progress/1)
  - [x] [`spinner/1`](https://hexdocs.pm/pyro/Pyro.Components.Extra.html#spinner/1)
  - [x] [`tooltip/1`](https://hexdocs.pm/pyro/Pyro.Components.Extra.html#tooltip/1)
  - [ ] Navbar/NavItem [#5]
  - [ ] SlideOver [#4]
  - [ ] Tabs [#13]
  - [ ] Breadcrumbs [#11]
  - [ ] Dark/Light theme selector [#3]
- [ ] Live Components
  - [x] [`Pyro.Components.Autocomplete`](https://hexdocs.pm/pyro/Pyro.Components.Autocomplete)
- [ ] Smart Components
  - [x] [`Pyro.Components.SmartForm`](https://hexdocs.pm/pyro/Pyro.Components.SmartForm)
  - [ ] `Pyro.Components.SmartDataTable` [#16]
  - [ ] `Pyro.Components.SmartCardGrid` [#10]
  - [ ] Extensible AshAuthentication support [#15]
- [ ] DX
  - [ ] Simplified setup [#2]
    - [ ] Create a Tailwind plugin
    - [ ] Figure out a better way to avoid needing to include `:reloadable_compilers` and `mix.exs` compilers config
  - [ ] Strong test suite
  - [ ] More override presets
  - [ ] Code patching tools [#1]

## Development

As long as Elixir is already installed:

```sh
git clone git@github.com:frankdugan3/pyro.git
cd pyro
mix setup
iex -S mix phx.server
```

You will now have a component previewer running on `http://localhost:9001` (running on that alternate port allows it to run alongside another app running the default Phoenix port). There are links to a component's hexdocs on every page in the component previewer.

> Note: The component previewer is intended exclusively for `Pyro` development, not as a showcase to demo how to use components. So, the previewer is very clunky and has no context as it is simply intended to be a very concise way for me to verify things are working properly. The components are documented on [HexDocs](https://hexdocs.pm/pyro).

If you are working on writing docs, there is a handy watcher script you can run to automatically rebuild/reload the docs locally:

```sh
./watch_docs.sh
```

### Welcome Contributions

- Improvements to default overrides (I am not a designer!)
- A better logo and banner
- [Open issues on Github](https://github.com/frankdugan3/pyro/issues)
- Things marked with `TODO:` in the codebase itself
- Fixes to obvious bugs/flaws
- Improvements to sloppy/redundant code
- Improvements to macros/compilers/generators/patchers
- Documentation improvements/more examples
- More tests/coverage, especially for components
- Getting `mix check` to pass 100%

Also open to more component ideas. Since it's easy to make your own components, there's little risk to writing your own then tossing the idea here to see if we want to pull it in officially. There is an issue template for component proposals.

## Prior Art

- [petal](https://petal.build/): Petal is an established project with a robust set of components, and served as a substantial inspiration for this project.
- [Surface UI](https://surface-ui.org/): Surface changed the game for LiveView. Many of its improvements have made it upstream, with the exceptions of special handling of classes and code patching tooling. Pyro has already tackled classes, and there are plans to do the same for code patching. [#1](https://github.com/frankdugan3/pyro/issues/1)
- [AshAuthenticationPhoenix](https://github.com/team-alembic/ash_authentication_phoenix): The component override system is pretty awesome, and directly inspired Pyro's override system.
