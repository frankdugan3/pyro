# Used by "mix format"
pyro_locals_without_parens = [
  set: 2,
  live_routes_for: 3
]

[
  import_deps: [:phoenix],
  locals_without_parens: pyro_locals_without_parens,
  export: [
    locals_without_parens: pyro_locals_without_parens
  ],
  plugins: [Phoenix.LiveView.HTMLFormatter, Styler],
  # HACK: Ignore files that need special module attribute ordering
  inputs:
    Enum.flat_map(
      [
        "*.{heex,ex,exs}",
        "{config,lib}/**/*.{heex,ex,exs}",
        "storybook/*.{heex,ex,exs}",
        "storybook/{config,lib,storybook}/**/*.{heex,ex,exs}"
      ],
      &Path.wildcard(&1, match_dot: true)
    ) --
      ["lib/pyro/component.ex", "lib/pyro/live_component.ex", "lib/pyro/live_view.ex"]
]
