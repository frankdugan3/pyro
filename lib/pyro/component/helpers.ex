defmodule Pyro.Component.Helpers do
  @moduledoc """
  A library of helpers for using/authoring Pyro components.
  """

  require Logger

  @gettext_module Application.compile_env(:pyro, :gettext)

  if @gettext_module do
    def gettext(text) do
      Gettext.gettext(@gettext_module, text)
    end

    @doc false
    def translate_error({msg, opts}) do
      if count = opts[:count] do
        Gettext.dngettext(@gettext_module, "errors", msg, msg, count, opts)
      else
        Gettext.dgettext(@gettext_module, "errors", msg, opts)
      end
    end
  else
    def gettext(text), do: text

    def translate_error({msg, opts}) do
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
      end)
    end
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
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
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
