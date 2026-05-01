defmodule Pyro.Design.Icon do
  @moduledoc false

  use Pyro.Dsl.Entity,
    name: :icon,
    args: [:name, :svg],
    describe: "Declare a named icon with inline SVG.",
    schema: [
      name: [type: :atom, required: true, doc: "Icon name (e.g., `:x`, `:chevron_down`)."],
      svg: [
        type: :string,
        required: true,
        doc: "Inline SVG markup. Use the `~SVG` sigil for syntax highlighting."
      ]
    ]
end
