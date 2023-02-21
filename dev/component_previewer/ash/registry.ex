defmodule ComponentPreviewer.Ash.Ash.Registry do
  @moduledoc false
  use Ash.Registry,
    extensions: [Ash.Registry.ResourceValidations]

  entries do
    entry(ComponentPreviewer.Ash.Ash.User)
  end
end
