defmodule PyroStorybookWeb.Storybook do
  @moduledoc false
  use PhoenixStorybook,
    otp_app: :pyro_storybook,
    content_path: Path.expand("../../storybook", __DIR__),
    # assets are endpoint paths, not local file-system paths
    css_path: "/assets/app.css",
    js_path: "/assets/storybook.js",
    sandbox_class: "pyro-storybook-web"
end
