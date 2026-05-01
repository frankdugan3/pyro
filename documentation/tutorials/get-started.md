# Get Started

This guide steps through the installation process for Pyro.

## Installation

1. Add `:pyro` to your dependencies:

   ```elixir
   def deps do
     [
       {:pyro, "~> 0.3.7"}
     ]
   end
   ```

2. Add `:pyro` to your `.formatter.exs`:

   ```elixir
   [
     import_deps: [:pyro], # <-- Add :pyro here
     # ...
   ]
   ```

3. Define a design module at `lib/my_app_web/design.ex`:

   ```elixir
   defmodule MyAppWeb.Design do
     use Pyro.Design

     config do
       namespace "myapp"
     end

     design do
       color :brand, "#0066cc"
     end
   end
   ```

That's it! See the [Design DSL reference](dsl-pyro-design.html) for the full vocabulary.
