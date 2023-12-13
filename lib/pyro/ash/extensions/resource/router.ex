if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.SmartRouter do
    @moduledoc """
    Tooling to generate routes for Pyro's LiveView page DSL.
    """

    @doc """
    Generates live routes for a given LiveView, resource and page.

    ```elixir
    defmodule ExampleWeb.Router do
      use ExampleWeb, :router
      import Pyro.Ash.Extensions.Resource.SmartRouter

      # ...

      scope "/", ExampleWeb do
        pipe_through :browser

        live_routes_for CompanyLive, Example.Company, :companies
        end
      end
    end
    ```
    """
    defmacro live_routes_for(live_view, resource, page_name) do
      live_view = Macro.expand(live_view, __CALLER__)
      resource = Macro.expand(resource, __CALLER__)
      pyro_page = Pyro.Ash.Extensions.Resource.Info.page_for(resource, page_name)

      routes =
        for %{path: path, live_action: live_action} <- pyro_page.live_actions do
          quote do
            live unquote(path),
                 unquote(live_view),
                 unquote(live_action)
          end
        end

      quote do
        unquote(routes)
      end
    end
  end
end
