# Get Started

This guide steps through the installation process for `Pyro`.

## Installation

The installation process is pretty straightforward, and many of the steps can be customized depending on how you want to use `Pyro`.

### Steps

These steps assume you are adding `Pyro` to an existing Phoenix LiveView app, as generated from the most recent version of `phx.new`.

1. Add `:pyro` to your dependencies:

   ```elixir
   def deps do
     [
    {:pyro, "~> 0.2.0"},

    # Heroicon support in components
    {:heroicons,
      github: "tailwindlabs/heroicons",
      tag: "v2.1.1",
      app: false,
      compile: false,
      sparse: "optimized"},

    ### OPTIONAL DEPS BELOW ###

    # Date/Time/Zone components & tooling
    {:tz, "~> 0.26"},
    {:tz_extra, "~> 0.26"},
    #   or
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

2. Add `:pyro` to your `.formatter.exs`:

   ```elixir
   [
     import_deps: [:ecto, :ecto_sql, :phoenix, :pyro],
     subdirectories: ["priv/*/migrations"],
     plugins: [Phoenix.LiveView.HTMLFormatter],
     inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
   ]
   ```

3. Add the following to your `config.exs`:

   ```elixir
   config :pyro, :overrides, [Pyro.Overrides.Default]
   config :pyro, gettext: MyApp.Gettext # optional
   ```

4. Configure your `tailwind.config.js` according to this example:

   ```js
   const path = require('path')

   module.exports = {
     // Dark mode support
     darkMode: 'class',
     content: [
       // The usual defaults
       './js/**/*.js',
       '../lib/my_app_web.ex',
       '../lib/my_app_web/**/*.*ex',

       // Add the directory you will be keeping resources since
       // we need to include any classes referenced in the UI DSL
       '../lib/my_app/**/*.ex',

       // Add your chosen Pyro overrides file(s)
       '../deps/pyro/lib/pyro/overrides/default.ex',
     ],
     plugins: [
       // Pyro expects the forms plugin
       require('@tailwindcss/forms'),
       // Add Pyro's Tailwind plugin
       require(path.join(
         __dirname,
         '../deps/pyro/assets/js/tailwind-plugin.js',
       ))({
         heroIconsPath: path.join(__dirname, '../deps/heroicons/optimized'),
         addBase: true,
       }),

       // Pyro replaces Phoenix's generated plugin stuff, you can delete it!
     ],
   }
   ```

   > #### Note: {: .warning}
   >
   > Using `path.join(.__dirname, '...')` is important; Tailwind CLI will get confused without it!

5. Add the following lines to `assets/js/app.js`:

   ```js
   import { hooks, getTimezone } from 'pyro'

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

8. (Optional) Add the color scheme JS to your `root.html.heex` template (prevents [FOUC](https://en.wikipedia.org/wiki/Flash_of_unstyled_content)):

   ```heex
   <head>
     <.color_scheme_switcher_js />
     <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
   </head>
   ```

   At this point, you probably want to delete the old `core_components.ex` file, since Pyro will replace that functionality (mostly API-compatible).

9. (Optional) configure some runtime options in `runtime.exs`:

   ```elixir
   config :pyro, default_timezone: "America/Chicago"
   ```
