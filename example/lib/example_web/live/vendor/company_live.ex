defmodule ExampleWeb.Vendor.CompanyLive do
  use ExampleWeb, :live_view

  use Pyro.Components.SmartPage,
    resource: Example.Vendor.Company,
    page: :companies
end