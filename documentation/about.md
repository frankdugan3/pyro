# About

`Pyro` is a component library for `Phoenix` with (optional) declarative UI for [`Ash Framework`](`Ash`). Specifically, it provides five things:

1. Component tooling
2. A component library for `Phoenix`
3. A declarative UI DSL extension for [`Ash Framework`](`Ash`)
4. "Smart components" for [`Ash Framework`](`Ash`)
5. Overrides (Themes)

## What "problem" is it solving?

The default model of Phoenix is to generate, then customize. While this does provide great isolation, I have found it pretty tedious to repeatedly make very similar copy & paste boilerplate changes to the generated code _every_ time I create a new Phoenix app. Additionally, some things (like timezone localization and extended Ecto types) are quite complicated and it would be nice for them to be handled by a library that is updated with future improvements. Copy & pasting boilerplate will lead to maintenance burdens down the road.

The tricky part is handling all the bespoke features in each app while sharing as much as possible. The goal is to provide a wide array of helpers and components with sane defaults, while allowing _very_ granular overrides.

[`Ash Framework`](`Ash`) provides an _excellent_ foundation for this on the backend. It's deep extensibility allows the DSL to be extended, and that's exactly where Pyro shifts into overdrive. By combining the flexible configuration of components with Ash's extensible DSL, Pyro can seamlessly add declarative UI config.

## General Principles

- Maximal flexibility
  - Application defaults through presets & custom overrides
  - Bespoke configuration (via DSL in resources)
  - Components allow overriding defaults through props
- Clean, standards-compliant HTML markup
  - Avoid senseless `div`s
  - Use the right tag(s) for the job
  - Use native, semantic HTML where possible
- Progressive enhancement
  - Don't _require_ JS (where possible)
  - Use JS to _enhance_ UX (where sensible)
  - No external JS dependencies
  - Should be able to bundle with ESBuild (no Node/NPM).
- Accessible
- Responsive
- Built-in `i18n` via `gettext` (internationalization)
