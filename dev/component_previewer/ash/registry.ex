defmodule ComponentPreviewer.Ash.Registry do
  @moduledoc false
  use Ash.Registry,
    extensions: [Ash.Registry.ResourceValidations]

  entries do
    entry(ComponentPreviewer.Ash.User)
  end
end
