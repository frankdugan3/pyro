defmodule Pyro.Components do
  @moduledoc """
  The easiest way to use Pyro components is to import them into `my_app_web.ex` helpers to make the available in all views and components:

   ```elixir
   defp html_helpers do
     quote do
       # Import all Pyro components
       use Pyro.Components
       # ...
   ```

  Comprehensive installation instructions can be found in [Get Started](get-started.md).

  Pyro provides components that support deep customization through `Pyro.Overrides`, and also tooling to create your own via `Pyro.Component`.

  > #### Note: {: .warning}
  >
  > Pyro's component names conflict with the generated `CoreComponents`. You will need to remove `import MyAppWeb.CoreComponents`.
  """

  defmacro __using__(_) do
    quote do
      import Pyro.Components.Core
      import Pyro.Components.DataTable

      alias Pyro.Components.Autocomplete
    end
  end
end
