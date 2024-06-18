# Get Started

This guide steps through the installation process for Pyro.

## Installation

Would you believe you can install Pyro in three easy steps? It's true.

### Steps

> #### Note: {: .info}
>
> We assume you are adding Pyro to an existing Phoenix LiveView app, as generated from the most recent version of `phx.new`.

1. Add `:pyro` to your dependencies:

   ```elixir
   def deps do
     [
      {:pyro, "~> 0.3.7"},

      ### OPTIONAL DEPS BELOW ###

      # Enables Timezone tooling
      {:tz_extra, "~> 0.26"},
      # or
      {:tzdata, "~> 1.0"},
     ]
   end
   ```

2. Add `:pyro` to your `.formatter.exs`:

   ```elixir
   [
     import_deps: [:ecto, :ecto_sql, :phoenix, :pyro], # <-- Add :pyro here
     # ...
   ]
   ```

3. Create a component module `lib/my_app_web/components/my_components.ex`:

   ```elixir
   defmodule MyAppWeb.MyComponents do
     @moduledoc false
     use Pyro, component_libraries: [] # <-- Import other component modules here
   end
   ```
That's it! You're ready to rock.

## Next Steps

The tutorials are sorted in a way to step you through how everything fits together, so go ahead and mash that "Next Page" link below.
