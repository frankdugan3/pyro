defmodule Example.Vendor do
  use Ash.Api

  authorization do
    authorize :by_default
    require_actor? true
  end

  resources do
    resource Example.Vendor.Company
  end
end