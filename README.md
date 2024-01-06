[![hex.pm](https://img.shields.io/hexpm/l/pyro.svg)](https://hex.pm/packages/pyro)
[![hex.pm](https://img.shields.io/hexpm/v/pyro.svg)](https://hex.pm/packages/pyro)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/pyro)
[![hex.pm](https://img.shields.io/hexpm/dt/pyro.svg)](https://hex.pm/packages/pyro)
[![github.com](https://img.shields.io/github/last-commit/frankdugan3/pyro.svg)](https://github.com/frankdugan3/pyro)

# Pyro

Phoenix components and tooling.

**NOTICE:** This library is under heavy development. Expect frequent breaking
changes until the first stable v1.0 release is out.

Pyro's documentation is housed on [hexdocs](https://hexdocs.pm/pyro), which includes detailed [installation instructions](https://hexdocs.pm/pyro/get-started.html) and other guides.

## Installation

Installation is covered in the [Get Started](https://hexdocs.pm/pyro/get-started.html) guide.

## What is Pyro?

Pyro provides a few things:

1. [Component tooling](https://hexdocs.pm/pyro/Pyro.Component.html) for Phoenix LiveView
2. A library of [pre-built components](https://hexdocs.pm/pyro/Pyro.Components.Core.html)
3. A set of [default](https://hexdocs.pm/pyro/Pyro.Overrides.Default.html), [customizable](https://hexdocs.pm/pyro/Pyro.Overrides.html) skins

For more details, check out the [About](https://hexdocs.pm/pyro/about.html) page.

Additionally, the related package [AshPyro](https://hexdocs.pm/ash_pyro) extends `Pyro` with:

1. An [Ash extension](https://hexdocs.pm/ash_pyro/AshPyro.Extensions.Resource.html) providing a declarative UI DSL
2. A [library of components](https://hexdocs.pm/ash_pyro/AshPyro.Components.html) that automatically render the UI DSL

## Roadmap to 1.0

- Complete implementation of key components/features
- Add `pyro.new` generator
- Reasonable test coverage
- Write adequate guides
- Dogfood website
- Collect feedback/stabilize API

## Development

As long as Elixir is already installed:

```sh
git clone git@github.com:frankdugan3/pyro.git
cd pyro
mix setup
```

For writing docs, there is a handy watcher script that automatically rebuilds/reloads the docs locally: `./watch_docs.sh`

## Prior Art

- [petal](https://petal.build/): Petal is an established project with a robust set of components, and served as a substantial inspiration for this project.
- [Surface UI](https://surface-ui.org/): Surface changed the game for LiveView. Many of its improvements have made it upstream.
- [AshAuthenticationPhoenix](https://github.com/team-alembic/ash_authentication_phoenix): The component override system is pretty awesome, and directly inspired Pyro's override system.
