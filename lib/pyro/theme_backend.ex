defmodule Pyro.ThemeBackend do
  @moduledoc """
  The behvavior for implementing Pyro theme backends.
  """
  @callback something() :: :noop
  def something(), do: :noop
  @optional_callbacks something: 0
end
