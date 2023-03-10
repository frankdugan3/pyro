defmodule ComponentPreviewer do
  @moduledoc false

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: ComponentPreviewer,
        formats: [:html, :json],
        layouts: [html: ComponentPreviewer.Layouts]

      import Plug.Conn
      import ComponentPreviewer.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phlegethon.LiveView,
        layout: {ComponentPreviewer.Layouts, :app},
        container:
          {:main,
           class: "grid overflow-hidden gap-2 p-4 grid-rows-[auto,auto,1fr] grid-cols-[auto,1fr]"}

      import AshPhoenix.LiveView

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phlegethon.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phlegethon.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Import all Phlegethon components
      use Phlegethon.Components
      alias Phlegethon.Info, as: UI

      # HTML escaping functionality
      import Phoenix.HTML

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())

      import ComponentPreviewer.Components
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ComponentPreviewer.Endpoint,
        router: ComponentPreviewer.Router,
        statics: ComponentPreviewer.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
