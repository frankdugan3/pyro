# Get Started

This guide steps through the installation process for Pyro.

## Installation

The installation process is pretty straightforward.

### Steps

These steps assume you are adding Pyro to an existing Phoenix LiveView app, as generated from the most recent version of `phx.new`.

1. Add `:pyro` to your dependencies:

   ```elixir
   def deps do
     [
      {:pyro, "~> 0.3.1"},

      ### OPTIONAL DEPS BELOW ###

      # Date/Time/Zone components & tooling
      {:tz, "~> 0.26"},
      {:tz_extra, "~> 0.26"},
      #   or
      {:tzdata, "~> 1.1"},
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
   config :pyro, :overrides, [MyApp.Overrides]
   config :pyro, gettext: MyApp.Gettext # optional
   ```

   See `Pyro.Overrides` to learn how to create your own overrides file.

4. Edit your `my_app_web.ex` file, replacing:

   - `Phoenix.Component` with `Pyro.Component`
   - `Phoenix.LiveComponent` with `Pyro.LiveComponent`
   - `Phoenix.LiveView` with `Pyro.LiveView`

   **Note:** _Only_ replace those top-level modules, _do not_ replace submodules, e.g. `Phoenix.LiveView.Router`.

5. (Optional) configure some runtime options in `runtime.exs`:

   ```elixir
   config :pyro, default_timezone: "America/Chicago"
   ```
