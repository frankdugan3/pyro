defmodule ComponentPreviewer.BackLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      &lt;.back&gt;<:actions>
        <.doc_url page="Phlegethon.Components.Core.html#back/1" />
      </:actions>
    </.header>

    <.code
      language="heex"
      class="text-sm"
      source={~s|<.back navigate={~p"/"}>Go back to the about page.</.back>|}
    />
    <.back navigate={~p"/"}>Go back to the about page.</.back>

    <.code
      language="heex"
      class="text-sm"
      source={~s|<.back icon_name={:arrow_left} navigate={~p"/"}>Go back to the about page.</.back>|}
    />
    <.back icon_name={:arrow_left} navigate={~p"/"}>Go back to the about page.</.back>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "<.back>")}
  end
end
