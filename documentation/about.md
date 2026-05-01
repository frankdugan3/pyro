# About

[![hex.pm](https://img.shields.io/hexpm/l/pyro.svg)](https://hex.pm/packages/pyro)
[![hex.pm](https://img.shields.io/hexpm/v/pyro.svg)](https://hex.pm/packages/pyro)
[![hex.pm](https://img.shields.io/hexpm/dt/pyro.svg)](https://hex.pm/packages/pyro)
[![github.com](https://img.shields.io/github/last-commit/frankdugan3/pyro.svg)](https://github.com/frankdugan3/pyro)

> A DTCG-conformant design system DSL for Elixir.

Pyro is a [suite of libraries](suite.md) for building UI in Elixir.

- **Design** declares design tokens and modifiers as a [DTCG](https://www.designtokens.org/tr/2025.10/format)-conformant token tree. Design modules layer through the `:sources` option, following DTCG Resolver semantics — each Design merges the tokens of its listed sources before applying its own.

To install Pyro and learn how it works, start at the [Get Started](get-started.html) guide.

> #### Experimental {: .warning}
>
> Pyro is in early development, expect breaking changes.

## But wait, there's more!

In addition to the Design DSL, there is a [full suite](suite.html) of libraries that build on the foundation Pyro provides.

- [Pyro](https://github.com/frankdugan3/pyro) - A DTCG-conformant design system DSL for Elixir.
- [PyroManiac](https://github.com/frankdugan3/pyro_maniac) - Declarative, framework-agnostic UI for Ash resources. Automatically render with PyroComponents.

