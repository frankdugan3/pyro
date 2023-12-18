defmodule ExampleWeb.SessionSetTimezoneController do
  @moduledoc false
  use ExampleWeb, :controller

  def set(conn, %{"timezone" => timezone}) when is_binary(timezone) do
    conn |> put_session(:timezone, timezone) |> json(%{})
  end
end
