# Used by "mix format"
spark_locals_without_parens = [
  action: 1,
  action: 2,
  action_type: 1,
  action_type: 2,
  autofocus: 1,
  class: 1,
  default_card_fields: 1,
  default_display_mode: 1,
  default_foreign_label: 1,
  default_sort: 1,
  default_table_columns: 1,
  description: 1,
  field: 1,
  field: 2,
  field_group: 2,
  field_group: 3,
  input_class: 1,
  label: 1,
  module: 1,
  path: 1,
  resource_label: 1,
  route_path: 1,
  type: 1
]

phlegethon_locals_without_parens = [
  overridable: 2,
  overridable: 3,
  set: 2
]

[
  import_deps: [
    :phoenix,
    :ash
    # :ash_authentication,
    # :ash_authentication_phoenix
  ],
  subdirectories: ["priv/*/migrations"],
  locals_without_parens: spark_locals_without_parens ++ phlegethon_locals_without_parens,
  export: [
    locals_without_parens: spark_locals_without_parens ++ phlegethon_locals_without_parens
  ],
  plugins: [Spark.Formatter, Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib}/**/*.{heex,ex,exs}"]
]
