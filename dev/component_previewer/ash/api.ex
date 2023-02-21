defmodule ComponentPreviewer.Ash.Ash.Api do
  @moduledoc false
  use Ash.Api

  resources do
    registry(ComponentPreviewer.Ash.Ash.Registry)
  end
end
