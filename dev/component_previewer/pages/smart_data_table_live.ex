defmodule ComponentPreviewer.SmartDataTableLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  alias ComponentPreviewer.Ash.User

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.table&gt;
      <:actions>
        <.button phx-click="generate_user">Generate User</.button>
        <.doc_url page="Phlegethon.Components.SmartDataTable.html#smart_data_table/1" />
      </:actions>
    </.header>

    <.live_component
      module={SmartDataTable}
      id="smart-data-table-users"
      resource={User}
      rows={@streams.users}
    />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:page_title, "<.table>")
      |> stream(:users, ComponentPreviewer.Ash.User.list!())
      #  TODO: Figure out how to support streams in `keep_live`
      #  |> keep_live(
      #    :users,
      #    fn _socket, _page_opts -> ComponentPreviewer.Ash.User.list!() end,
      #    refetch_interval: :timer.minutes(10),
      #    subscribe: ~w[user:created user:updated user:destroyed],
      #    results: :lose
      #  )
    }
  end

  @impl true
  def handle_event("generate_user", _params, socket) do
    user =
      User.create!(%{
        name: Faker.Person.name(),
        email: Faker.Internet.email(),
        notes: Faker.Util.pick([Faker.Lorem.sentence(4..10), nil, nil, nil])
      })

    {:noreply,
     socket
     |> put_flash(
       :success,
       encode_flash(~s|User "#{user.name}" successfully created!|,
         title: "User Generated",
         icon_name: "hero-user-circle-mini"
       )
     )}
  end

  @impl true
  def handle_event("delete_user", %{"id" => id}, socket) do
    User.by_id!(id)
    |> User.destroy!()

    {:noreply, socket}
  end

  # TODO: Re-enable later
  # @impl true
  # def handle_info(%{topic: topic, payload: %Ash.Notifier.Notification{}}, socket) do
  #   {:noreply, handle_live(socket, topic, :users)}
  # end

  # @impl true
  # def handle_info({:refetch, assign, opts}, socket) do
  #   {:noreply, handle_live(socket, :refetch, assign, opts)}
  # end
end
