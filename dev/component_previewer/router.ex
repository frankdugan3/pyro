defmodule ComponentPreviewer.Router do
  @moduledoc false
  use ComponentPreviewer, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {ComponentPreviewer.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/", ComponentPreviewer do
    pipe_through(:browser)

    live_session :page, on_mount: ComponentPreviewer.Hooks.Page do
      live("/", AboutLive)
      live("/a", ALive)
      live("/back", BackLive)
      live("/button", ButtonLive)
      live("/code", CodeLive)
      live("/copy-to-clipboard", CopyToClipboardLive)
      live("/flash", FlashLive)
      live("/error", ErrorLive)
      live("/header", HeaderLive)
      live("/icon", IconLive)
      live("/input", InputLive)
      live("/label", LabelLive)
      live("/list", ListLive)
      live("/modal", ModalLive)
      live("/progress", ProgressLive)
      live("/spinner", SpinnerLive)
      live("/tooltip", TooltipLive)
      live("/simple-form", SimpleFormLive)
      live("/smart-form", SmartFormLive)
      live("/table", TableLive)
    end
  end
end
