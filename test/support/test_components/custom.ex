defmodule Pyro.TestComponents.Custom do
  @moduledoc false

  use Pyro, component_libraries: [Pyro.TestComponents.Core]
  #   css_output_path: "tmp/test_components",
  #   component_output_path: "tmp/test_components"
  #
  # component :simple do
  #   class :class, ~E|simple| do
  #     strategy :tailwind
  #
  #     template ~E"""
  #     .<%= @base_class %> {
  #       background: red;
  #     }
  #     """
  #   end
  #
  #   attr :text, :string, default: "asd"
  #
  #   template ~H"""
  #   <div id="special">{@text}</div>
  #   """
  # end
  #
  # component :a do
  #   attr :href, :string, required: true
  #   slot :inner_block, required: true, doc: "the content of the link"
  #
  #   template ~H"""
  #   <a ref={@href}>{render_slot(@inner_block)}</a>
  #   """
  # end
end
