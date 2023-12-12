[![hex.pm](https://img.shields.io/hexpm/l/pyro.svg)](https://hex.pm/packages/pyro)
[![hex.pm](https://img.shields.io/hexpm/v/pyro.svg)](https://hex.pm/packages/pyro)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/pyro)
[![hex.pm](https://img.shields.io/hexpm/dt/pyro.svg)](https://hex.pm/packages/pyro)
[![github.com](https://img.shields.io/github/last-commit/frankdugan3/pyro.svg)](https://github.com/frankdugan3/pyro)

# Pyro

Phoenix components and tooling with (optional) declarative UI for Ash Framework.

**NOTICE:** This library is under heavy development. Expect frequent breaking
changes until the first stable v1.0 release is out.

Pyro's documentation is housed on [hexdocs](https://hexdocs.pm/pyro), which includes detailed [installation instructions](https://hexdocs.pm/pyro/get-started.html) and other guides.

## Dependencies

```elixir
def deps do
  [
    {:pyro, "~> 0.2.0"},
    {:ash_phoenix, "~> 1.2"}, # Optional: Ash integration
    {:ash, "~> 2.4"}, # Optional: Ash integration
    {:makeup_eex, "~> 0.1.1"}, # Optional: Code highlighting components
    {:makeup_elixir, "~> 0.16"}, # Optional: Code highlighting components
    {:makeup_html, "~> 0.1.0"}, # Optional: Code highlighting components
    {:makeup_js, "~> 0.1.0"}, # Optional: Code highlighting components
    {:makeup_json, "~> 0.1.0"}, # Optional: Code highlighting components
    {:makeup, "~> 1.1"}, # Optional: Code highlighting components
    {:timex, "~> 3.0"}, # Optional: Date/Time/Zone components & tooling
    {:tzdata, "~> 1.1.0"}, # Optional: Date/Time/Zone components & tooling
  ]
end
```

## What is Pyro?

1. [Component tooling](https://hexdocs.pm/pyro/Pyro.Component.html) for Phoenix LiveView
2. A library of [pre-built components](https://hexdocs.pm/pyro/Pyro.Components.Core.html) to cover most common UI requirements
3. An [Ash extension](https://hexdocs.pm/pyro/Pyro.Resource.html) providing a declarative UI DSL
4. A library of (optional) "smart components" that leverage 1-3 to automatically render [forms](https://hexdocs.pm/pyro/Pyro.Components.SmartForm.html)/[data tables](https://hexdocs.pm/pyro/Pyro.Components.SmartDataTable.html)/etc. for Ash resources
5. A set of [default](https://hexdocs.pm/pyro/Pyro.Overrides.Default.html), [customizable](https://hexdocs.pm/pyro/Pyro.Overrides.html) themes for all the above

For more details, check out the [About](https://hexdocs.pm/pyro/about.html) page.

## Roadmap

- [ ] Function Components
  - [ ] Navbar/NavItem [#5](https://github.com/frankdugan3/pyro/issues/5)
  - [ ] SlideOver [#4](https://github.com/frankdugan3/pyro/issues/4)
  - [ ] Tabs [#13](https://github.com/frankdugan3/pyro/issues/13)
  - [ ] Breadcrumbs [#11](https://github.com/frankdugan3/pyro/issues/11)
- [ ] Smart Components
  - [ ] `Pyro.Components.SmartDataTable` [#16](https://github.com/frankdugan3/pyro/issues/16)
  - [ ] `Pyro.Components.SmartCardGrid` [#10](https://github.com/frankdugan3/pyro/issues/10)
  - [ ] Extensible AshAuthentication support [#15](https://github.com/frankdugan3/pyro/issues/15)
- [ ] DX
  - [ ] Strong test suite
  - [ ] More override presets
  - [ ] Code patching tools [#1](https://github.com/frankdugan3/pyro/issues/1)

## Development

As long as Elixir is already installed:

```sh
git clone git@github.com:frankdugan3/pyro.git
cd pyro
mix setup
```

If you are working on writing docs, there is a handy watcher script you can run to automatically rebuild/reload the docs locally:

```sh
./watch_docs.sh
```

### Welcome Contributions

- Improvements to default overrides (I am not a designer!)
- A logo and banner
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
