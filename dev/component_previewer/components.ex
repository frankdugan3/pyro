defmodule ComponentPreviewer.Components do
  @moduledoc false
  use Pyro.Component
  import Pyro.Components.Core, only: [button: 1]

  attr :page, :string, required: true

  def doc_url(assigns) do
    page = assigns[:page]

    assigns =
      assign_new(assigns, :uri, fn ->
        with server <- Application.get_env(:pyro, :ex_doc_server),
             uri <- Path.join([server, page]),
             {:ok, %{status: 200}} <-
               Finch.build(:get, uri) |> Finch.request(ComponentPreviewer.Finch) do
          uri
        else
          _ -> Path.join("/doc/", page)
        end
      end)

    ~H"""
    <.button href={@uri} target="_blank">View ExDoc</.button>
    """
  end
end
