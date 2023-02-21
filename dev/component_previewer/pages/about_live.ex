defmodule ComponentPreviewer.AboutLive do
  @moduledoc false
  use ComponentPreviewer, :live_view

  alias ComponentPreviewer.Ash.Ash.User

  @impl true
  def render(assigns) do
    ~H"""
    <.header>About</.header>

    <p>
      The component previewer is mostly for demonstrating the various options for components, and for testing that they work as expected. It is not intended as documentation. The documentation for components is provided via ExDoc.
    </p>

    <p>
      You can find the source for Phlegethon on
      <.button
        href="https://github.com/frankdugan3/phlegethon"
        target="_blank"
        class="whitespace-nowrap"
        size="sm"
      >
        <.icon name={:code_bracket} /> GitHub <.icon name={:arrow_right_on_rectangle} />
      </.button>. Installation/development instructions can be found in the project's README.
    </p>

    <p>
      The premiere feature of this library, aside from highly the extensible generic components, is the <strong>smart components</strong>.
      The <var>phlegethon</var>
      extension integrates with the smart components to automatically render UI components, like complex forms and data tables.
      Like many things in Ash, there are multiple "escape hatches" and ways to override defaults at many levels.
    </p>

    <p>
      Check out the
      <.button size="sm" navigate={~p"/smart-form"}><%= "<.smart_form>" %></.button>
      page for examples!
    </p>

    <.code source={File.read!(User.__info__(:compile)[:source])} class="text-xs" />
    <.code
      source={"# UI.form_for(User, :create)\n" <> inspect(UI.form_for(User, :create), pretty: true)}
      class="text-xs"
    />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "About")}
  end
end
