defmodule Example.Authentication do
  @moduledoc false
  use Ash.Api

  authorization do
    authorize :by_default
    require_actor? false
  end

  resources do
    resource Example.Authentication.User
    resource Example.Authentication.Token
  end
end
