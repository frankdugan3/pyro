if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Type.ZonedDateTime do
    @moduledoc false
    use Ash.Type

    def graphql_input_type(_), do: :create_zoned_date_time_input
    def graphql_type(_), do: :datetime

    @impl Ash.Type
    def storage_type, do: :utc_datetime_usec

    @impl Ash.Type
    def cast_input(value, _) do
      Ecto.Type.cast(EctoZonedDateTime, value)
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
