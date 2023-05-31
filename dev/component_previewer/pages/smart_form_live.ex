defmodule ComponentPreviewer.SmartFormLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  alias ComponentPreviewer.Ash.User

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.smart_form&gt;
      <:actions>
        <.doc_url page="Pyro.Components.SmartForm.html#smart_form/1" />
      </:actions>
    </.header>

    <.code
      id="code-example-create"
      source="<.smart_form resource={User} for={@create_user_form} ... />"
      language="heex"
      class="text-xs"
    />

    <.smart_form
      resource={User}
      for={@create_user_form}
      phx-change="validate_create_user_form"
      phx-submit="save_create_user_form"
    />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "<.smart_form>")
     |> assign(:create_user_form, reset_create_user_form())}
  end

  @impl true
  def handle_event("validate_create_user_form", %{"create_user_form" => params}, socket) do
    form =
      socket.assigns.create_user_form
      |> AshPhoenix.Form.validate(params)

    {:noreply, assign(socket, :create_user_form, form)}
  end

  @impl true
  def handle_event("save_create_user_form", %{"create_user_form" => params}, socket) do
    case socket.assigns.create_user_form
         |> AshPhoenix.Form.submit(params: params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:success, ~s|User "#{user.name}" successfully created!|)
         |> assign(:create_user_form, reset_create_user_form())}

      {:error, form} ->
        {:noreply, assign(socket, :create_user_form, form)}
    end
  end

  @impl true
  def handle_event("reset_create_user_form", _params, socket) do
    {:noreply, assign(socket, :create_user_form, reset_create_user_form())}
  end

  defp reset_create_user_form(),
    do:
      AshPhoenix.Form.for_create(User, :create,
        forms: [auto?: true],
        api: ComponentPreviewer.Ash.Api,
        as: "create_user_form"
      )
end
