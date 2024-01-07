defmodule PyroStorybook.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: PyroStorybook.PubSub},
      PyroStorybookWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: PyroStorybook.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PyroStorybookWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
