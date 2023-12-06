if Code.ensure_loaded?(Ash) && Code.ensure_loaded?(Timex) do
  defmodule Pyro.Ash.Type.ZonedDateTime do
    @moduledoc false
    use Ash.Type

    def graphql_input_type(_), do: :create_zoned_date_time_input
    def graphql_type(_), do: :datetime

    @impl Ash.Type
    def storage_type, do: :utc_datetime_usec

    @impl Ash.Type
    def cast_input(nil, _), do: {:ok, nil}

    @impl Ash.Type
    def cast_input(%{"date_time" => ""}, _), do: {:ok, nil}

    @impl Ash.Type
    def cast_input(%{"time_zone" => time_zone, "date_time" => date_time}, _) do
      with {:ok, naive} <- Ecto.Type.cast(:naive_datetime_usec, date_time),
           dt <- Timex.to_datetime(naive, time_zone) do
        {:ok, Timex.Timezone.convert(dt, "Etc/UTC")}
      else
        _ ->
          :error
      end
    end

    @impl Ash.Type
    def cast_input(%{"time_zone" => time_zone} = map, _) do
      with {:ok, naive} <- Ecto.Type.cast(:naive_datetime_usec, map),
           dt <- Timex.to_datetime(naive, time_zone) do
        {:ok, Timex.Timezone.convert(dt, "Etc/UTC")}
      else
        _ -> :error
      end
    end

    @impl Ash.Type
    def cast_input(value, _) do
      Ecto.Type.cast(:utc_datetime_usec, value)
    end

    @impl Ash.Type
    def cast_stored(value, constraints) do
      cast_input(value, constraints)
    end

    @impl Ash.Type
    def dump_to_native(value, _) do
      Ecto.Type.dump(EctoZonedDateTime, value)
    end

    @impl Ash.Type
    def equal?(left, right), do: left == right
  end
end
