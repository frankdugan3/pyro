# Get Started

This guide steps through the installation process for `Pyro`.

## Installation

The installation process is currently pretty involved, and may be omitting some required steps. This will [improve over time](https://github.com/frankdugan3/pyro/issues/2), pinky-promise!

### Steps

These steps assume you are adding `Pyro` to an existing Phoenix LiveView app as generated from the `v1.7.2+` `phx.new`.

1. Add `:pyro` to your dependencies:

   ```elixir
   def deps do
     [
       {:pyro, "~> 0.2.0"},
       {:tails, "~> 0.1.5"}, # <-- Optional: Smart-merge Tailwind component classes
       {:ash, "~> 2.0"}, # <-- Optional: Ash integration
       {:ash_phoenix, "~> 1.0"}, # <-- Optional: Ash integration
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

4. Add the chosen theme's CSS to `assets/css/app.css`:

   ```css
   @import 'tailwindcss/base';
   @import 'tailwindcss/components';
   @import 'tailwindcss/utilities';

   @import '../deps/pyro/priv/static/css/Default.css';
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

6. Edit your `my_app_web.ex` file, replacing:

   - `Phoenix.Component` with `Pyro.Component`
   - `Phoenix.LiveComponent` with `Pyro.LiveComponent`
   - `Phoenix.LiveView` with `Pyro.LiveView`

   **Note:** _Only_ replace those top-level modules, _do not_ replace submodules, e.g. `Phoenix.LiveView.Router`.

7. (Optional) Import the Pyro components into your `my_app_web.ex` helpers to make the available in your views/components:

   ```elixir
   defp html_helpers do
     quote do
       # Import all Pyro components
       use Pyro.Components
       # Don't import CoreComponents since Pyro replaces it and will conflict
       # import MyAppWeb.CoreComponents
       # ...
   ```
