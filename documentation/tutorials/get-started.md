# Get Started

Wow, you must be courageous! Be sure to [check out open issues](https://github.com/frankdugan3/pyro/issues) before proceeding.

## Installation

The installation process is currently pretty involved, and may be omitting some required steps. This will [improve over time](https://github.com/frankdugan3/pyro/issues/2), pinky-promise!

### Requirements

This library is for Phoenix LiveView & Ash Framework

- Phoenix v1.7.1+
- Tailwind

### Steps

These steps assume you are adding Pyro to an existing Phoenix LiveView app as generated from the `v1.7.1+` `phx.new`.

1. Until we approach a stable release candidate, there will be no releases on Hex, so install via GitHub:

   ```elixir
   def deps do
     [
       {:pyro, github: "frankdugan3/pyro", branch: "main"}
     ]
   end
   ```

2. Add the following to your `config.exs`:

   ```elixir
   config :pyro, :overrides, [Pyro.Overrides.Default]
   ```

3. Update your `tailwind.config.js`, and add the noted lines:

   ```js
   let plugin = require('tailwindcss/plugin')

   module.exports = {
     darkMode: 'class', // <-- Dark theme support
     content: [
       // ...
       '../deps/pyro/lib/pyro/**/*.*ex', // <-- Ensure Pyro components are included
     ],
     // ...
     plugins: [
       // In addition to the normal `phx` variants, add the following:
       plugin(({ addVariant }) =>
         addVariant('aria-selected', '&[aria-selected]'),
       ),
       plugin(({ addVariant }) =>
         addVariant('aria-checked', '&[aria-checked]'),
       ),
     ],
   }
   ```

4. Add `pyro` CSS imports to `assets/css/app.css`:

   ```css
   @import 'tailwindcss/base';
   @import 'tailwindcss/components';
   @import 'tailwindcss/utilities';

   @import './pyro.css';
   ```

5. Add the following lines to `assets/js/app.js`:

   ```js
   import { hooks, getTimezone } from 'pyro'
   // ...
   let liveSocket = new LiveSocket('/live', Socket, {
     params: { _csrf_token: csrfToken, timezone: getTimezone() },
     hooks: { ...hooks },
   })
   ```

6. Update `mix.exs`, adding the `:pyro` compiler to the list of compilers:

   ```elixir
   def project do
     [
       # ...
       compilers: Mix.compilers() ++ [:pyro]
     ]
   end
   ```

   And update `config/dev.exs` to include `:pyro` in the list of `:reloadable_compilers` in your endpoint:

   ```elixir
   config :my_app, MyAppWeb.Endpoint,
     # ...
     reloadable_compilers: [:elixir, :app, :pyro],
   ```

7. Edit your `my_app_web.ex` file, replacing:

   - `Phoenix.Component` with `Pyro.Component`
   - `Phoenix.LiveComponent` with `Pyro.LiveComponent`
   - `Phoenix.LiveView` with `Pyro.LiveView`

   **Note:** _Only_ replace those top-level modules, _do not_ replace submodules, e.g. `Phoenix.LiveView.Router`.

8. (Optional) Add the generated files to your `.gitignore` if you don't want them tracked:

   ```
   /assets/css/pyro.css
   ```

9. (Optional) Import the Pyro components into your `my_app_web.ex` helpers to make the available in your views/components:

   ```elixir
   defp html_helpers do
     quote do
       # Import all Pyro components
       use Pyro.Components
       # Don't import CoreComponents since Pyro replaces it and will conflict
       # import MyAppWeb.CoreComponents
       # ...
   ```

10. Note: `Tails` may occasionally complain about the `colors_file` being different in runtime than compile time. You simply need to run `mix deps.compile tails --force` to clear it up. If you are using the `Tails` helper functions for custom colors, you will also need to force a recompile if those change. If you are extending the default color theme, you will need to [configure the colors](https://github.com/zachdaniel/tails#colors).
