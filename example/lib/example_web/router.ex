defmodule ExampleWeb.Router do
  use ExampleWeb, :router
  use AshAuthentication.Phoenix.Router
  import Pyro.Ash.Extensions.Resource.SmartRouter

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ExampleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
  end

  scope "/", ExampleWeb do
    pipe_through :browser

    ash_authentication_live_session :authentication_optional,
      on_mount: {ExampleWeb.LiveUserAuth, :live_user_optional} do
      live_routes_for Vendor.CompanyLive, Example.Vendor.Company, :companies
    end

    sign_in_route register_path: "/register", reset_path: "/reset"
    sign_out_route AuthController
    auth_routes_for Example.Authentication.User, to: AuthController
    reset_route []
  end

  # Other scopes may use custom stacks.
  # scope "/api", ExampleWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:example, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ExampleWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
