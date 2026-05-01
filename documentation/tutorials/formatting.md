# Formatting

## Pyro.Formatter

Pyro provides an optional formatter that uses [Prettier](https://prettier.io) to handle formatting supported files/sigils (e.g. `~JS`).

See `Pyro.Formatter` for setup instructions.

## Spark.Formatter

Since Pyro is built on `Spark`, its formatter can be configured to:

- Remove paranthesis in DSL
- Customize the section order

To set that up, only two things need to be configured.

Add the formatter to `.formatter.exs`

```elixir
[
  # Add :pyro to the list of import deps:
  import_deps: [:pyro],
  # Add Spark.Formatter to the list of plugins:
  plugins: [Spark.Formatter],
  # ...
]
```

Configure the formatter in `config/config.exs`:

```elixir
config :spark, :formatter,
  remove_parens?: true,
  "Pyro.Design": [
    section_order: [
      :design,
      :icons,
      :config
    ]
  ]
```

For more advanced uses, check out the upstream `Spark.Formatter` docs.
