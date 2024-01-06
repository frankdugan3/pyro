defmodule ExampleWeb.Vendor.EmployeeLive do
  @moduledoc false
  use ExampleWeb, :live_view

  use SmartPage,
    resource: Example.Vendor.Employee,
    page: :employees,
    router: ExampleWeb.Router
end
