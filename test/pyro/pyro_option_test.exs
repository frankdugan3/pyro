defmodule Pyro.OptionTest do
  @moduledoc false
  use ExUnit.Case, async: true

  # alias Pyro.TestComponents.Custom
  #
  # test "imported components are present in DSL" do
  #   button = Pyro.Info.component(Custom, :button)
  #   assert %{name: :button} = button
  # end
  #
  # test "top-level components are present in DSL" do
  #   a = Pyro.Info.component(Custom, :a)
  #   assert %{name: :a} = a
  # end
  #
  # test "declarative metadata is present" do
  #   assert %{} = Custom.__components__().button
  #   assert %{} = Custom.__components__().a
  # end
  #
  # test "default options are propagated from libraries" do
  #   assert :tailwind = Pyro.Info.css_strategy(Custom)
  # end
end
