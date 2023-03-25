# Get Started

Wow, you must be courageous! Be sure to [check out open issues](https://github.com/frankdugan3/phlegethon/issues) before proceeding.

## Installation

The installation process is currently pretty involved, and may be omitting some required steps. This will [improve over time](https://github.com/frankdugan3/phlegethon/issues/2), pinky-promise!

### Requirements

This library is for Phoenix LiveView & Ash Framework

- Phoenix v1.7.1+
- Tailwind

### Steps

These steps assume you are adding Phlegethon to an existing Phoenix LiveView app as generated from the `v1.7.1+` `phx.new`.

1. Until we approach a stable release candidate, there will be no releases on Hex, so install via GitHub:

   ```elixir
   def deps do
     [
       {:phlegethon, github: "https://github.com/frankdugan3/phlegethon", branch: "main"}
     ]
   end
   ```

2. Add the following lines to your `config.exs`:

   ```elixir
   config :tails, colors_file: Path.join(File.cwd!(), "assets/tailwind.phlegethon.colors.json")
   config :phlegethon, :overrides, [Phlegethon.Overrides.Default]
   ```

3. Update your `tailwind.config.js`, and add the noted lines:

   ```js
   let plugin = require('tailwindcss/plugin')

   module.exports = {
     darkMode: 'class', // <-- Dark theme support
     content: [
       // ...
       '../deps/phlegethon/lib/phlegethon/**/*.*ex', // <-- Ensure Phlegethon components are included
     ],
     theme: {
       extend: {
         colors: {
           ...require('./tailwind.phlegethon.colors.json'), // <-- Include colors from Phlegethon
         },
       },
     },
     // ...
   }
   ```

4. Add `phlegethon` CSS imports to `assets/css/app.css`:

   ```css
   @import 'tailwindcss/base';
   @import 'tailwindcss/components';
   @import 'tailwindcss/utilities';

   @import './phlegethon.css';
   ```

5. Add the following lines to `assets/js/app.js`:

   ```js
   import { hooks, getTimezone } from 'phlegethon'
   // ...
   let liveSocket = new LiveSocket('/live', Socket, {
     params: { _csrf_token: csrfToken, timezone: getTimezone() },
     hooks: { ...hooks },
   })
   ```

6. Update `mix.exs`, adding the `:phlegethon` compiler to the list of compilers:

   ```elixir
   def project do
     [
       # ...
       compilers: Mix.compilers() ++ [:phlegethon]
     ]
   end
   ```

   And update `config/dev.exs` to include `:phlegethon` in the list of `:reloadable_compilers` in your endpoint:

   ```elixir
   config :my_app, MyAppWeb.Endpoint,
     # ...
     reloadable_compilers: [:elixir, :app, :phlegethon],
   ```

7. Edit your `my_app_web.ex` file, replacing:

   - `Phoenix.Component` with `Phlegethon.Component`
   - `Phoenix.LiveComponent` with `Phlegethon.LiveComponent`
   - `Phoenix.LiveView` with `Phlegethon.LiveView`

   **Note:** _Only_ replace those top-level modules, _do not_ replace submodules, e.g. `Phoenix.LiveView.Router`.

8. (Optional) Add the generated files to your `.gitignore` if you don't want them tracked:

   ```
   /assets/tailwind.phlegethon.colors.json
   /assets/css/phlegethon.css
   ```

9. (Optional) Import the Phlegethon components into your `my_app_web.ex` helpers to make the available in your views/components:

   ```elixir
   defp html_helpers do
     quote do
       # Import all Phlegethon components
       use Phlegethon.Components
       # ...
   ```

10. Run `mix phlegethon.setup`.

11. Note: `Tails` may occasionally complain about the `colors_file` being different in runtime than compile time. You simply need to run `mix deps.compile tails --force` to clear it up. If you are using the `Tails` helper functions for custom colors, you will also need to force a recompile if those change.
