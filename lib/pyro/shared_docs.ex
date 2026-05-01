defmodule Pyro.SharedDocs do
  @moduledoc false

  # NOTE: Keep these in sync with README.md, GitHub, and mix.exs -> @description
  def pyro_tagline,
    do: "A DTCG-conformant design system DSL for Elixir."

  def pyro_maniac_tagline,
    do:
      "Declarative, framework-agnostic UI for Ash resources. Automatically render with PyroComponents."

  def suite_list do
    """
    - [Pyro](https://github.com/frankdugan3/pyro) - #{pyro_tagline()}
    - [PyroManiac](https://github.com/frankdugan3/pyro_maniac) - #{pyro_maniac_tagline()}
    """
  end
end
