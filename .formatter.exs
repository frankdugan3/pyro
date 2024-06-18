# Used by "mix format"
spark_locals_without_parens = [
  attr: 1,
  attr: 2,
  attr: 3,
  calculate: 1,
  class: 1,
  class: 2,
  class: 3,
  component: 1,
  component: 2,
  default: 1,
  doc: 1,
  examples: 1,
  hook: 2,
  hook: 3,
  live_component: 1,
  live_component: 2,
  normalizer: 1,
  private?: 1,
  required: 1,
  slot: 1,
  slot: 2,
  strategy: 1,
  strategy: 2,
  strategy: 3,
  template: 1,
  validate_attrs: 1,
  values: 1,
  variables: 1,
  variants: 1
]

[
  import_deps: [:phoenix],
  locals_without_parens: spark_locals_without_parens,
  export: [locals_without_parens: spark_locals_without_parens],
  plugins: [Phoenix.LiveView.HTMLFormatter, Spark.Formatter, Styler],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,vhs,test}/**/*.{heex,ex,exs}",
    "cli/{config,lib,vhs,test}/**/*.{heex,ex,exs}"
  ]
]
