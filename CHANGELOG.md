# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.3.7](https://github.com/frankdugan3/pyro/compare/v0.3.6...v0.3.7) (2024-01-26)




### Bug Fixes:

* clean up macro bugs

## [v0.3.6](https://github.com/frankdugan3/pyro/compare/v0.3.5...v0.3.6) (2024-01-22)




## [v0.3.5](https://github.com/frankdugan3/pyro/compare/v0.3.4...v0.3.5) (2024-01-22)




## [v0.3.4](https://github.com/frankdugan3/pyro/compare/v0.3.3...v0.3.4) (2024-01-18)




## [v0.3.3](https://github.com/frankdugan3/pyro/compare/v0.3.2...v0.3.3) (2024-01-18)




### Bug Fixes:

* apparently, need to filter opts

## [v0.3.2](https://github.com/frankdugan3/pyro/compare/v0.3.1...v0.3.2) (2024-01-18)




### Bug Fixes:

* remove stray unquote

## [v0.3.1](https://github.com/frankdugan3/pyro/compare/v0.3.0...v0.3.1) (2024-01-18)




### Bug Fixes:

* formatter exceptions

## [v0.3.0](https://github.com/frankdugan3/pyro/compare/v0.2.0...v0.3.0) (2024-01-12)

This release represents major restructuring, and it comes with lots of breaking changes.

Pyro has been split into four libraries for the sake of separation of concerns and simplificiation:

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

Some of these libraries are still in the process of being released, so double-check the features you need are available before upgrading!

You will want to look at the "Get Started" guide in the library for the highest level of features you want, as each guide is structured to cover installing all the needed Pyro libs.

### Breaking Changes:

- split components into pyro_components repo
- split ash extension into ash_pyro
- split "smart" components into ash_pyro_components
