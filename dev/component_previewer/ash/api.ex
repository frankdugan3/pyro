defmodule ComponentPreviewer.Ash.Api do
  @moduledoc false
  use Ash.Api

  resources do
    registry(ComponentPreviewer.Ash.Registry)
  end
end
