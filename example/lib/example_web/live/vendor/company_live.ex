defmodule ExampleWeb.Vendor.CompanyLive do
  use ExampleWeb, :live_view

  use SmartPage,
    resource: Example.Vendor.Company,
    page: :companies,
    router: ExampleWeb.Router
end
