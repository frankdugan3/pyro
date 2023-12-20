defmodule EctoZonedDateTime do
  @moduledoc false
  @behaviour Ecto.Type

  def type, do: :utc_datetime_usec

  def cast(nil), do: {:ok, nil}

  def cast(%{"date_time" => ""}), do: {:ok, nil}

  def cast(%{"time_zone" => time_zone, "date_time" => date_time}) do
    parse_input(date_time, time_zone)
  end

  def cast(%{"time_zone" => time_zone} = map) do
    parse_input(map, time_zone)
  end

  def cast(value) do
    Ecto.Type.cast(:utc_datetime_usec, value)
  end

  def embed_as(_format), do: :self

  def equal?(left, right), do: left == right

  def dump(value), do: Ecto.Type.dump(:utc_datetime_usec, value)

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
