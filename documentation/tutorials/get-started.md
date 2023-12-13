# Get Started

This guide steps through the installation process for `Pyro`.

## Installation

The installation process is pretty straightforward, and many of the steps can be customized depending on how you want to use `Pyro`.

### Steps

These steps assume you are adding `Pyro` to an existing Phoenix LiveView app as generated from the `v1.7.10+` `phx.new`.

1. Add `:pyro` to your dependencies:

   ```elixir
   def deps do
     [
    {:pyro, "~> 0.2.0"},

    # Heroicon support in components
    {:heroicons,
      github: "tailwindlabs/heroicons",
      tag: "v2.0.18",
      app: false,
      compile: false,
      sparse: "optimized"},

    ### OPTIONAL DEPS BELOW ###

    # Ash resource extension to declare UI via DSL
    {:ash, "~> 2.4"},

    # "Smart" components that build UI from DSL
    {:ash_phoenix, "~> 1.2"},

    # Date/Time/Zone components & tooling
    {:timex, "~> 3.0"},
    {:tzdata, "~> 1.1"},

    # Code highlighting components:
    {:makeup, "~> 1.1"},
    {:makeup_eex, "~> 0.1"},
    {:makeup_elixir, "~> 0.16"},
    {:makeup_html, "~> 0.1"},
    {:makeup_js, "~> 0.1"},
    {:makeup_json, "~> 0.1"},
     ]
   end
   ```

2. Add the following to your `config.exs`:

   ```elixir
   config :pyro, :overrides, [Pyro.Overrides.Default]
   ```

3. Update your `tailwind.config.js`, this is a working example configuration:

   ```js
   const path = require('path')

   module.exports = {
     darkMode: 'class', // <-- Dark theme support
     content: [
       './js/**/*.js',
       '../lib/my_app_web.ex',
       '../lib/my_app_web/**/*.*ex',
       '../deps/pyro/lib/pyro/**/*.*ex', // <-- Add Pyro's component and overrides files
     ],
     plugins: [
       require('@tailwindcss/forms'), // <-- Pyro expects this
       // Add Pyro's Tailwind plugin
       require(path.join(
         __dirname,
         '../deps/pyro/assets/js/tailwind-plugin.js',
       ))({
         heroIconsPath: path.join(__dirname, '../deps/heroicons/optimized'),
       }),
       // ... Pyro replaces Phoenix's generated plugin stuff, you can delete it!
     ],
   }
   ```

   > #### Note: {: .warning}
   >
   > Using `path.join(.__dirname, '...')` is important; Tailwind CLI will get confused without it!

4. Add the following lines to `assets/js/app.js`:

   ```js
   import { hooks, getTimezone } from 'pyro'
   // ...
   let liveSocket = new LiveSocket('/live', Socket, {
     params: { _csrf_token: csrfToken, timezone: getTimezone() },
     hooks: { ...hooks },
   })
   ```

5. Edit your `my_app_web.ex` file, replacing:

   - `Phoenix.Component` with `Pyro.Component`
   - `Phoenix.LiveComponent` with `Pyro.LiveComponent`
   - `Phoenix.LiveView` with `Pyro.LiveView`

   **Note:** _Only_ replace those top-level modules, _do not_ replace submodules, e.g. `Phoenix.LiveView.Router`.

6. Add the color scheme JS to your `root.html.heex` template (prevents FOUC):

   ```heex
   <head>
     <!-- ... -->
     <.color_scheme_switcher_js />
     <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
   </head>
   ```

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

   At this point, you probably want to delete the old `core_components.ex` file, since Pyro will replace that functionality (mostly API-compatible).

8. (Optional) If you are using Ash, you'll want to add `:pyro` to your `.formatter.exs`:

   ```elixir
   [
     import_deps: [:ash, :ash_postgres, :ecto, :ecto_sql, :phoenix, :pyro],
     subdirectories: ["priv/*/migrations"],
     plugins: [Spark.Formatter, Phoenix.LiveView.HTMLFormatter],
     inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
   ]
   ```
