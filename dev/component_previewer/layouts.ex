defmodule ComponentPreviewer.Layouts do
  @moduledoc false
  use ComponentPreviewer, :html

  embed_templates("layouts/*")
end
