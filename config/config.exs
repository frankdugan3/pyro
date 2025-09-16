import Config

config :logger, level: :warning

# if Mix.env() == :test do
#   config :mix_test_watch, tasks: ["test", "credo"]
# end

if Mix.env() == :dev do
  config :mix_test_interactive,
    timestamp: true,
    clear: true,
    task: "test_and_lint"

  config :spark, :formatter,
    remove_parens?: true,
    "Pyro.ComponentLibrary": [
      section_order: [
        :theme,
        :tailwind,
        :component
      ]
    ]

  config :git_ops,
    mix_project: Mix.Project.get!(),
    changelog_file: "CHANGELOG.md",
    repository_url: "https://github.com/frankdugan3/pyro",
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
    manage_readme_version: ["README.md", "documentation/tutorials/get-started.md"],
    version_tag_prefix: "v"
end
