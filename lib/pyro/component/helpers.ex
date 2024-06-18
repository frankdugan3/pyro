defmodule Pyro.Component.Helpers do
  @moduledoc """
  A library of helpers for using/authoring Pyro components.
  """

  require Logger

  @doc ~S'''
  Encode a flash message as a JSON binary with extra metadata options. This is necessary because Phoenix only allows binary messages.

  This allows you to override the defaults for:

  * `:title` - The title above the message
  * `:close` - Auto-close the flash after `:ttl`
  * `:ttl` - The time-to-live in milliseconds
  * `:icon_name` - Name of the icon displayed in the title
  * `:kind` - Override which kind of style this flash should have

  ## Examples

  ```elixir
  socket
  |> put_flash(
    encode_flash(
      :success,
      """
      This flash closes when it *wants to*.
      And has a custom title and icon.
      """,
      title: "TOTALLY CUSTOM",
      ttl: 6_000,
      icon_name: "hero-beaker"
    )
  )
  ```
  '''
  @type encode_flash_opts ::
          {:ttl, pos_integer()}
          | {:title, binary()}
          | {:icon_name, binary()}
          | {:close, boolean()}
          | {:kind, binary()}
  @spec encode_flash(binary() | atom(), binary(), [encode_flash_opts()]) :: {binary(), binary()}
  def encode_flash(kind, message, opts) when is_atom(kind) do
    encode_flash(Atom.to_string(kind), message, opts)
  end

  def encode_flash(kind, message, opts) do
    {kind,
     Jason.encode!(%{
       "ttl" => opts[:ttl],
       "title" => opts[:title],
       "icon_name" => opts[:icon_name],
       "close" => opts[:close],
       "kind" => opts[:kind],
       "message" => message
     })}
  end

  @spec decode_flash(map(), atom() | binary()) :: keyword()
  def decode_flash(flash, kind) when is_atom(kind) do
    decode_flash(flash, Atom.to_string(kind))
  end

  def decode_flash(flash, kind) do
    message = Phoenix.Flash.get(flash, kind)

    message
    |> Jason.decode()
    |> case do
      {:ok, %{"message" => _message} = parsed} ->
        Enum.reduce(parsed, defaults_for_flash(kind), fn
          {"message", _}, acc ->
            acc

          {_key, nil}, acc ->
            acc

          {"icon_name", value}, acc ->
            Keyword.put(acc, :icon_name, value)

          {"ttl", value}, acc ->
            Keyword.put(acc, :ttl, value)

          {"title", value}, acc ->
            Keyword.put(acc, :title, value)

          {"close", value}, acc ->
            Keyword.put(acc, :close, value)

          {"kind", value}, acc ->
            Keyword.put(acc, :kind, value)
        end)

      _ ->
        [{:message, message} | defaults_for_flash(kind)]
    end
  end

  defp defaults_for_flash(kind) do
    title = kind |> String.split(" ") |> Enum.map_join(" ", &String.capitalize/1)
    [key: kind, kind: kind, ttl: 0, title: title]
  end

  @doc """
  Provides a configurable fallback timezone. Defaults to `"Etc/UTC"`.

  ```elixir
  # runtime.exs
  config :pyro, default_timezone: "America/Chicago"
  ```

  > #### Note: {: .warning}
  >
  > Requires a timezone database to be properly installed and configured.
  """
  def default_timezone do
    Application.get_env(:pyro, :default_timezone, "Etc/UTC")
  end

  def local_now, do: local_now(default_timezone())

  def local_now(tz) do
    case DateTime.now(tz) do
      {:ok, datetime} -> datetime
      _ -> DateTime.utc_now()
    end
  end

  @doc """
  Formats datetimes to localized format.

  ## Examples
      iex> format_datetime(DateTime.new!(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC"), default_timezone())
      "2016-05-24 13:26 UTC"

      iex> format_datetime(~N[2000-01-01 23:00:07], "Etc/UTC")
      "2000-01-01 23:00 UTC"

      iex> format_datetime(~N[2000-01-01 23:00:07], "Etc/UTC", :date_time_seconds_timezone)
      "2000-01-01 23:00:07 UTC"

      iex> format_datetime(nil, "Etc/UTC")
      ""

      iex> format_datetime("", "Etc/UTC")
      ""
  """
  def format_datetime(timestamp, tz, formatter \\ &simple_datetime_formatter/1)

  def format_datetime(timestamp, tz, format) when is_atom(format) do
    format_datetime(timestamp, tz, &simple_datetime_formatter(&1, format))
  end

  def format_datetime(%NaiveDateTime{} = naive, tz, formatter) when is_function(formatter, 1) do
    case DateTime.from_naive(naive, tz) do
      {:ok, datetime} ->
        apply(formatter, [datetime])

      {:ambiguous, first_datetime, _second_datetime} ->
        apply(formatter, [first_datetime])

      {:gap, just_before, _just_after} ->
        apply(formatter, [just_before])

      _ ->
        apply(formatter, [nil])
    end
  end

  def format_datetime(%DateTime{} = timestamp, tz, formatter) when is_function(formatter, 1) do
    case DateTime.shift_zone(timestamp, tz) do
      {:ok, shifted} -> apply(formatter, [shifted])
      _ -> ""
    end
  end

  def format_datetime(other, _tz, formatter) when is_function(formatter, 1) do
    apply(formatter, [other])
  end

  defp simple_datetime_formatter(datetime, format \\ :date_time_timezone)

  defp simple_datetime_formatter(%DateTime{} = ts, :date_time_timezone) do
    year = ts.year |> Integer.to_string() |> String.pad_leading(4, "0")
    month = ts.month |> Integer.to_string() |> String.pad_leading(2, "0")
    day = ts.day |> Integer.to_string() |> String.pad_leading(2, "0")
    hour = ts.hour |> Integer.to_string() |> String.pad_leading(2, "0")
    minute = ts.minute |> Integer.to_string() |> String.pad_leading(2, "0")

    "#{year}-#{month}-#{day} #{hour}:#{minute} #{ts.zone_abbr}"
  end

  defp simple_datetime_formatter(%DateTime{} = ts, :date_time_seconds_timezone) do
    year = ts.year |> Integer.to_string() |> String.pad_leading(4, "0")
    month = ts.month |> Integer.to_string() |> String.pad_leading(2, "0")
    day = ts.day |> Integer.to_string() |> String.pad_leading(2, "0")
    hour = ts.hour |> Integer.to_string() |> String.pad_leading(2, "0")
    minute = ts.minute |> Integer.to_string() |> String.pad_leading(2, "0")
    second = ts.second |> Integer.to_string() |> String.pad_leading(2, "0")

    "#{year}-#{month}-#{day} #{hour}:#{minute}:#{second} #{ts.zone_abbr}"
  end

  defp simple_datetime_formatter(_, _), do: ""

  cond do
    Code.ensure_loaded?(TzExtra) ->
      def all_timezones, do: TzExtra.time_zone_identifiers(include_alias: true)

    Code.ensure_loaded?(TzData) ->
      def all_timezones, do: Tzdata.zone_list()

    true ->
      def all_timezones, do: [default_timezone()]
  end

  @doc """
  Safely get nested values from maps or keyword lists that may be `nil` or an otherwise non-map value at any point. Great for accessing nested assigns in a template.

  ## Examples

      iex> get_nested(nil, [:one, :two, :three])
      nil

      iex> get_nested(%{one: nil}, [:one, :two, :three])
      nil

      iex> get_nested(%{one: %{two: %{three: 3}}}, [:one, :two, :three])
      3

      iex> get_nested(%{one: %{two: [three: 3]}}, [:one, :two, :three])
      3

      iex> get_nested([one: :nope], [:one, :two, :three])
      nil

      iex> get_nested([one: :nope], [:one, :two, :three], :default)
      :default
  """
  def get_nested(value, keys, default \\ nil)
  def get_nested(value, [], _), do: value
  def get_nested(%{} = map, [key], default), do: Map.get(map, key, default)

  def get_nested(%{} = map, [key | keys], default), do: get_nested(Map.get(map, key), keys, default)

  def get_nested([_ | _] = keyword, [key], default), do: Keyword.get(keyword, key, default)

  def get_nested([_ | _] = keyword, [key | keys], default), do: get_nested(Keyword.get(keyword, key), keys, default)

  def get_nested(_, _, default), do: default
end
