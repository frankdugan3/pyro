defmodule Phlegethon.Component.HelpersTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Phlegethon.Components.Core

  doctest Phlegethon.Component.Helpers, import: true

  def assigns, do: %{class: "bg-red-500", user: %{name: "John Doe"}, picks: [libs: "Ash"]}
end
