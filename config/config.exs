import Config

config :logger, level: :warning

if Mix.env() == :dev do
  config :git_ops,
    mix_project: Mix.Project.get!(),
    changelog_file: "CHANGELOG.md",
    repository_url: "https://github.com/frankdugan3/pyro",
    types: [
      tidbit: [hidden?: true],
      important: [header: "Important Changes"]
    ],
    manage_mix_version?: true,
    manage_readme_version: ["README.md", "documentation/tutorials/get-started.md"],
    version_tag_prefix: "v"

  config :spark, :formatter,
    remove_parens?: true,
    "Pyro.Design": [
      section_order: [
        :design,
        :icons,
        :config
      ]
    ]
end

if Mix.env() == :test do
  config :mix_test_watch, tasks: ["test", "credo"], clear: true
end
