# Used by "mix format"
spark_locals_without_parens = [
  context: 1,
  context: 2,
  default: 1,
  deprecated: 1,
  description: 1,
  extends: 1,
  extensions: 1,
  group: 1,
  group: 2,
  icon: 2,
  icon: 3,
  modifier: 1,
  modifier: 2,
  namespace: 1,
  property: 2,
  property: 3,
  raw: 1,
  raw: 2,
  ref: 1,
  root?: 1,
  selector: 1,
  selector: 2,
  tailwind_preamble: 1,
  token: 1,
  token: 2,
  type: 1,
  value: 1
]

macros = [
  # Top-level token macros (Pyro.Design.Macros)
  border: 2,
  color: 2,
  color: 3,
  cubic_bezier: 2,
  cubic_bezier: 3,
  dimension: 3,
  dimension: 4,
  duration: 3,
  duration: 4,
  font_family: 2,
  font_family: 3,
  font_weight: 2,
  font_weight: 3,
  gradient: 2,
  number: 2,
  number: 3,
  ref: 2,
  ref: 3,
  root: 2,
  root: 3,
  shadow: 2,
  stroke_style: 2,
  stroke_style: 3,
  transition: 2,
  typography: 2,

  # Composite-block field calls
  blur: 2,
  color: 1,
  dash_array: 1,
  delay: 2,
  duration: 2,
  font_family: 1,
  font_size: 2,
  font_weight: 1,
  letter_spacing: 2,
  line_cap: 1,
  line_height: 1,
  offset_x: 2,
  offset_y: 2,
  spread: 2,
  stop: 2,
  style: 1,
  timing_function: 4,
  width: 2
]

locals_without_parens = spark_locals_without_parens ++ macros

[
  migrate: true,
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens],
  plugins: [Spark.Formatter],
  inputs: [
    "*.{ex,exs}",
    "{config,lib,test}/**/*.{ex,exs}"
  ]
]
