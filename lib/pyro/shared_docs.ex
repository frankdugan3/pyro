defmodule Pyro.SharedDocs do
  @moduledoc false

  # NOTE: Keep these in sync with README.md, GitHub, and mix.exs -> @description
  def pyro_tagline,
    do:
      "Compose extensible, framework-agnostic components in Elixir. Built-in support for Phoenix LiveView and Hologram."

  def pyro_components_tagline,
    do:
      "Ready-made design and framework-agnostic components built with Pyro. Built-in support for Phoenix LiveView and Hologram."

  def pyro_maniac_tagline,
    do:
      "Declarative, framework-agnostic UI for Ash resources. Automatically render with PyroComponents."

  def suite_list do
    """
    - [Pyro](https://github.com/frankdugan3/pyro) - #{pyro_tagline()}
    - [PyroComponents](https://github.com/frankdugan3/pyro_components) - #{pyro_components_tagline()}
    - [PyroManiac](https://github.com/frankdugan3/pyro_maniac) - #{pyro_maniac_tagline()}
    """
  end
end
