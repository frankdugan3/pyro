# Formatter

Since Pyro is built on `Spark`, its formatter can be configured to:

- Remove paranthesis in DSL
- Customize the section order

To set that up, only two things need to be configured.

Add the formatter to `.formatter.exs`

```elixir
[
  # Add :pyro to the list of import deps:
  import_deps: [:ecto, :ecto_sql, :phoenix, :pyro],
  # Add Spark.Formatter to the list of plugins:
  plugins: [Phoenix.LiveView.HTMLFormatter, Spark.Formatter],
  # ...
]
```

Configure the formatter in `config/config.exs`:

```elixir
config :spark, :formatter,
  remove_parens?: true,
  "Pyro.Component": [
    section_order: [
      :components
    ]
  ]
```

For more advanced uses, check out the upstream `Spark.Formatter` docs.
