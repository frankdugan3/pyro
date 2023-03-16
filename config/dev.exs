import Config

config :phlegethon, :ex_doc_server, "http://127.0.0.1:35729/"

config :tails, colors_file: Path.join(File.cwd!(), "assets/tailwind.phlegethon.colors.json")

config :ash, :use_all_identities_in_manage_relationship?, false

config :ash, ash_apis: [ComponentPreviewer.Ash.Api]

if Mix.env() == :dev do
  config :ash, :policies, show_policy_breakdowns?: true
  config :ash, :policies, log_policy_breakdowns: :info

  # Configure esbuild (the version is required)
  config :esbuild,
    version: "0.16.17",
    default: [
      args:
        ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]

  # Configure tailwind (the version is required)
  config :tailwind,
    version: "3.2.6",
    default: [
      args: ~w(
        --config=tailwind.config.js
        --input=css/app.css
        --output=../priv/static/assets/app.css
    ),
      cd: Path.expand("../assets", __DIR__)
    ]

  # Use Jason for JSON parsing in Phoenix
  config :phoenix, :json_library, Jason

  config :phlegethon, ComponentPreviewer.Endpoint,
    adapter: Bandit.PhoenixAdapter,
    url: [host: "localhost"],
    render_errors: [
      formats: [html: ComponentPreviewer.ErrorHTML, json: ComponentPreviewer.ErrorJSON],
      layout: false
    ],
    pubsub_server: ComponentPreviewer.PubSub,
    live_view: [signing_salt: "XxQlIkmHahpJHwX1RiwSdvk5MwxiYJfdoOQ+Ui74D6IqCQaCuQCNqFpdUV9liabg"],
    # Binding to loopback ipv4 address prevents access from other machines.
    # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
    http: [ip: {127, 0, 0, 1}, port: 9001],
    check_origin: false,
    code_reloader: true,
    debug_errors: true,
    secret_key_base: "++Dkht3bZ4e3HUg3fvVstKs4W34p9ai9pm7jvq2ksAyAiek13qbl7Ges5683YmQI",
    watchers: [
      esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
      tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
    ],
    reloadable_compilers: [:elixir, :app, :phlegethon],
    live_reload: [
      patterns: [
        ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg|ico)$",
        ~r"priv/gettext/.*(po)$",
        ~r"lib/phlegethon/.*(ex)$",
        ~r"dev/component_previewer/(pages)/.*(ex)$",
        ~r"dev/component_previewer/layouts/.*(eex)$"
      ]
    ]

  config :phoenix, :stacktrace_depth, 20
  config :phoenix, :plug_init_mode, :runtime

  config :logger, :console, format: "[$level] $message\n"

  config :git_ops,
    mix_project: Mix.Project.get!(),
    changelog_file: "CHANGELOG.md",
    repository_url: "https://github.com/frankdugan3/phlegethon",
    types: [
      # Makes an allowed commit type called `tidbit` that is not
      # shown in the changelog
      tidbit: [
        hidden?: true
      ],
      # Makes an allowed commit type called `important` that gets
      # a section in the changelog with the header "Important Changes"
      important: [
        header: "Important Changes"
      ]
    ],
    # Instructs the tool to manage your mix version in your `mix.exs` file
    # See below for more information
    manage_mix_version?: true,
    # Instructs the tool to manage the version in your README.md
    # Pass in `true` to use `"README.md"` or a string to customize
    manage_readme_version: "README.md",
    version_tag_prefix: "v"
end
