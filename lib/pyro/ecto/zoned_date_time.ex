defmodule Pyro.Ecto.ZonedDateTime do
  @moduledoc """
  Wraps a datetime in a map with a timezone to edit/display datetimes in a given timezone in input components.
  """
  @behaviour Ecto.Type

  @doc false
  def type, do: :utc_datetime_usec

  @doc false
  def cast(nil), do: {:ok, nil}
  @doc false
  def cast(%{"date_time" => ""}), do: {:ok, nil}
  @doc false
  def cast(%{"time_zone" => time_zone, "date_time" => date_time}) do
    parse_input(date_time, time_zone)
  end

  @doc false
  def cast(%{"time_zone" => time_zone} = map) do
    parse_input(map, time_zone)
  end

  @doc false
  def cast(value) do
    Ecto.Type.cast(:utc_datetime_usec, value)
  end

  @doc false
  def embed_as(_format), do: :self
  @doc false
  def equal?(left, right), do: left == right
  @doc false
  def dump(value), do: Ecto.Type.dump(:utc_datetime_usec, value)
  @doc false
  def load(value), do: Ecto.Type.load(:utc_datetime_usec, value)

  defp parse_input(input, time_zone) do
    with {:ok, naive} <- Ecto.Type.cast(:naive_datetime_usec, input),
         {:ok, date_time} <- DateTime.from_naive(naive, time_zone),
         {:ok, utc_date_time} <- DateTime.shift_zone(date_time, "Etc/UTC") do
      {:ok, utc_date_time}
    else
      _ -> :error
    end
  end
end
