import Config

# config :phlegethon, ComponentPreviewer.Endpoint,
#   http: [ip: {127, 0, 0, 1}, port: 4002],
#   secret_key_base: "4t1mF8thWqNlx0ZpVKLcOJseDqKkptl7oOi0yBrqpDnKyNW9JBO+IZ5HBHdfOk4x",
#   server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :phlegethon, :overrides, [Phlegethon.Overrides.Testing, Phlegethon.Overrides.Default]
config :tails, colors_file: Path.join(File.cwd!(), "assets/tailwind.phlegethon.colors.json")
config :ash, :use_all_identities_in_manage_relationship?, false
