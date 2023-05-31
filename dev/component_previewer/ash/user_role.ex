defmodule ComponentPreviewer.Ash.UserRole do
  @moduledoc false

  use Ash.Type.Enum, values: [
    :reader,
    :author,
    :edit,
    :admin
  ]
end
