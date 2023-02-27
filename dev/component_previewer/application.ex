defmodule ComponentPreviewer.Application do
  @moduledoc false
  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Supervisor.child_spec({Finch, name: ComponentPreviewer.Finch}, id: ComponentPreviewer.Finch),
      {Phoenix.PubSub, name: ComponentPreviewer.PubSub},
      ComponentPreviewer.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ComponentPreviewer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ComponentPreviewer.Endpoint.config_change(changed, removed)
    :ok
  end
end
