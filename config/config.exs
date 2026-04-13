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

  config :mix_test_interactive,
    timestamp: true,
    clear: true,
    task: "test_and_lint"

  config :spark, :formatter,
    remove_parens?: true,
    "Pyro.Design": [
      section_order: [
        :design,
        :icons,
        :config
      ]
    ],
    "Pyro.Component": [
      section_order: [
        :design,
        :component,
        :live_view,
        :hologram
      ]
    ],
    "Pyro.ComponentLibrary": [
      section_order: [
        :design,
        :components,
        :live_view,
        :hologram
      ]
    ],
    "Pyro.Framework.LiveView": [],
    "Pyro.Framework.Hologram": []
end
