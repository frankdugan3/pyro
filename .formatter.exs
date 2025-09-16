# Used by "mix format"
spark_locals_without_parens = [
  calc: 2,
  calc: 3,
  classes: 1,
  component: 1,
  component: 2,
  default: 1,
  doc: 1,
  examples: 1,
  global: 1,
  global: 2,
  include: 1,
  private?: 1,
  prop: 2,
  prop: 3,
  render: 2,
  render: 3,
  required: 1,
  slot: 1,
  slot: 2,
  theme: 1,
  theme: 2,
  theme: 3,
  tokens: 1,
  type: 1,
  validate_attrs: 1,
  values: 1,
  variant: 1,
  variant: 2,
  variants: 1
]

[
  import_deps: [:phoenix],
  locals_without_parens: spark_locals_without_parens,
  export: [locals_without_parens: spark_locals_without_parens],
  quokka: [autosort: [:map, :defstruct, :schema]],
  plugins: [Quokka, Phoenix.LiveView.HTMLFormatter, Pyro.Formatter, Spark.Formatter],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,vhs,test}/**/*.{heex,ex,exs}",
    "cli/{config,lib,vhs,test}/**/*.{heex,ex,exs}"
  ]
]
