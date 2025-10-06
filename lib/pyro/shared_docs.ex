defmodule Pyro.SharedDocs do
  @moduledoc false

  # NOTE: Keep these in sync with README.md, GitHub, and mix.exs -> @description
  def pyro_tagline, do: "Compose extensible components for Phoenix."
  def pyro_components_tagline, do: "Extensible Phoenix components, built with Pyro."

  def pyro_maniac_tagline,
    do:
      "Extensible, declarative UI for Ash Framework. Built-in support for Phoenix LiveView and Hologram."

  def suite_list do
    """
    - [Pyro](https://github.com/frankdugan3/pyro) - #{pyro_tagline()}
    - [PyroComponents](https://github.com/frankdugan3/pyro_components) - #{pyro_components_tagline()}
    - [PyroManiac](https://github.com/frankdugan3/pyro_maniac) - #{pyro_maniac_tagline()}
    """
  end
end
