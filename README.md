[![hex.pm](https://img.shields.io/hexpm/l/pyro.svg)](https://hex.pm/packages/pyro)
[![hex.pm](https://img.shields.io/hexpm/v/pyro.svg)](https://hex.pm/packages/pyro)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/pyro)
[![hex.pm](https://img.shields.io/hexpm/dt/pyro.svg)](https://hex.pm/packages/pyro)
[![github.com](https://img.shields.io/github/last-commit/frankdugan3/pyro.svg)](https://github.com/frankdugan3/pyro)

# Pyro

Pyro is a suite of libraries for building UI in Phoenix.

- [Pyro](https://github.com/frankdugan3/pyro)

  Component tooling for Phoenix.

  - Customizable "overrides" system for granularly customizable themes
  - Extended component attributes, e.g. CSS merging

- [PyroComponents](https://github.com/frankdugan3/pyro_components)

  Ready-made Phoenix components, built with pyro.

  - Heex component library
  - Overrides presets to get started quickly while allowing deep customization

- [AshPyro](https://github.com/frankdugan3/ash_pyro)

  Declarative UI for Ash Framework.

  - Ash extensions providing a declarative UI DSL

- [AshPyroComponents](https://github.com/frankdugan3/ash_pyro_components)

  Components that automatically render PyroComponents declaratively via AshPyro.

## About

For more details on Pyro, check out the [About](https://hexdocs.pm/pyro/about.html) page.

## Installation

To install Pyro and write your own components, follow the [Get Started](https://hexdocs.pm/pyro/get-started.html) guide. For the other features, please see the "Get Started" guide for the appropriate library instead.

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
