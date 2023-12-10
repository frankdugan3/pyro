defmodule ExampleWeb.HomeLive do
  use ExampleWeb, :live_view

  alias Pyro.Resource.Info, as: UI

  @pyro_page UI.page_for(Example.Vendor.Company, :list)

  @impl true
  def render(assigns) do
    ~H"""
    <.smart_page
      resource={Example.Vendor.Company}
      page={:list}
      pyro_page={@pyro_page}
      actor={@current_user}
      tz="America/Chicago"
    />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:pyro_page, @pyro_page)
     |> assign(:current_user, nil)
     |> assign(:page_title, "Home")}
  end

  # defmacro live(opts) do
  #   quote bind_quoted: [path: path, opts: opts] do
  #     import Phoenix.LiveView.Router
  #     live_socket_path = Keyword.get(opts, :live_socket_path, "/live")

  #     live_session :ash_admin,
  #       on_mount: List.wrap(opts[:on_mount]),
  #       session:
  #         {AshAdmin.Router, :__session__, [%{"prefix" => path}, List.wrap(opts[:session])]},
  #       root_layout: {AshAdmin.Layouts, :root} do
  #       live(
  #         "#{path}/*route",
  #         AshAdmin.PageLive,
  #         :page,
  #         private: %{live_socket_path: live_socket_path}
  #       )
  #     end
  #   end
  # end
end
