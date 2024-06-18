[![hex.pm](https://img.shields.io/hexpm/l/pyro.svg)](https://hex.pm/packages/pyro)
[![hex.pm](https://img.shields.io/hexpm/v/pyro.svg)](https://hex.pm/packages/pyro)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/pyro)
[![hex.pm](https://img.shields.io/hexpm/dt/pyro.svg)](https://hex.pm/packages/pyro)
[![github.com](https://img.shields.io/github/last-commit/frankdugan3/pyro.svg)](https://github.com/frankdugan3/pyro)

# Pyro

> Compose extensible components for Phoenix.

> [!WARNING]
> Pyro is in early development, expect breaking changes.

Pyro is a suite of libraries for building UI in Phoenix.

- [Pyro](https://github.com/frankdugan3/pyro) - Compose extensible components for Phoenix.
- [PyroComponents](https://github.com/frankdugan3/pyro_components) - Extensible Phoenix components, built with Pyro.
- [AshPyro](https://github.com/frankdugan3/ash_pyro) - Declarative UI for Ash Framework.
- [AshPyroComponents](https://github.com/frankdugan3/ash_pyro_components) - Automatic rendering of AshPryo DSL.

## About

For more details on Pyro, check out the [About](https://hexdocs.pm/pyro/about.html) page.

## Installation

To install Pyro and learn how it works, start at the [Get Started](get-started.html) guide and work your way through the tutorials. They are ordered in a sensible way to explain the various features Pyro offers, and point toward other tools in the Pyro suite when appropriate.

## Development

As long as Elixir is already installed:

```sh
git clone git@github.com:frankdugan3/pyro.git
cd pyro
mix setup
```

For writing docs, there is a handy watcher script that automatically rebuilds/reloads the docs locally: `./watch_docs.sh`

## Prior Art

- [Surface UI](https://surface-ui.org/): Surface changed the game for LiveView. Many of its improvements have made it upstream.
- [AshAuthenticationPhoenix](https://github.com/team-alembic/ash_authentication_phoenix): The component override system is pretty awesome, and directly inspired Pyro's override system.
