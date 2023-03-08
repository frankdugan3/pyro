defmodule Phlegethon.Components do
  @moduledoc """
  The easiest way to use Phlegethon components is to import them into `my_app_web.ex` helpers to make the available in all views and components:

   ```elixir
   defp html_helpers do
     quote do
       # Import all Phlegethon components
       use Phlegethon.Components
       # ...
   ```

   Comprehensive installation instructions can be found in [Get Started](get-started.md).

   Phlegethon provides components that support deep customization through `Phlegethon.Overrides`, and also tooling to create your own via `Phlegethon.Component`.
  """

  defmacro __using__(_) do
    quote do
      import Phlegethon.Components.Core
      import Phlegethon.Components.Extra
      import Phlegethon.Components.SmartForm
      alias Phlegethon.Components.SmartDataTable
    end
  end
end
