defmodule Pyro.Component.Helpers do
  @moduledoc """
  A library of helpers for using/authoring Pyro components.
  """

  require Logger

  alias Phoenix.LiveView.JS

  # Lifted from this comment: https://github.com/phoenixframework/phoenix_live_view/pull/1721#issuecomment-1439701395
  @doc """
  A [`JS`](`Phoenix.LiveView.JS`) function to toggle CSS classes, since Phoenix does not yet provide one out of the box.

  ## Examples

      toggle_class("rotate-180 bg-green", to: "#icon")
  """
  @spec toggle_class(js :: map(), classes :: String.t(), opts :: keyword()) :: map()
  def toggle_class(js \\ %JS{}, classes, opts) when is_binary(classes) do
    if not Keyword.has_key?(opts, :to) do
      raise ArgumentError, "Missing option `:to`"
    end

    case String.split(classes) do
      [class] ->
        opts_remove_class = Keyword.update!(opts, :to, fn selector -> "#{selector}.#{class}" end)

        opts_add_class =
          Keyword.update!(opts, :to, fn selector -> "#{selector}:not(.#{class})" end)

        js
        |> JS.remove_class(class, opts_remove_class)
        |> JS.add_class(class, opts_add_class)

      classes ->
        Enum.reduce(classes, js, fn class, js ->
          toggle_class(js, class, opts)
        end)
    end
  end

  @gettext_module Application.compile_env(:pyro, :gettext)

  if @gettext_module do
    def gettext(text) do
      apply(@gettext_module, :gettext, [text])
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
  config :pyro, default_timezone: "America/Chicago"
  ```

  > #### Note: {: .warning}
  >
  > Requires a timezone database to be properly installed and configured.
  """
  def default_timezone() do
    Application.get_env(:pyro, :default_timezone, "Etc/UTC")
  end

  def local_now(), do: local_now(default_timezone())

  def local_now(tz) do
    case DateTime.now(tz) do
      {:ok, datetime} -> datetime
      _ -> DateTime.utc_now()
    end
  end

  def format_datetime(timestamp, tz, formatter \\ &simple_datetime_formatter/1)

  def format_datetime(timestamp, tz, format) when is_atom(format) do
    format_datetime(timestamp, tz, &simple_datetime_formatter(&1, format))
  end

  def format_datetime(timestamp, tz, formatter) when is_function(formatter, 1) do
    case DateTime.shift_zone(timestamp, tz) do
      {:ok, shifted} -> apply(formatter, [shifted])
      _ -> ""
    end
  end

  defp simple_datetime_formatter(datetime, format \\ :date_time_timezone)

  defp simple_datetime_formatter(%NaiveDateTime{} = ts, formatter) do
    case DateTime.from_naive(ts, default_timezone()) do
      {:ok, datetime} ->
        simple_datetime_formatter(datetime, formatter)

      {:ambiguous, first_datetime, _second_datetime} ->
        simple_datetime_formatter(first_datetime, formatter)

      {:gap, just_before, _just_after} ->
        simple_datetime_formatter(just_before, formatter)

      _ ->
        ""
    end
  end

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

  def get_nested(%{} = map, [key | keys], default),
    do: get_nested(Map.get(map, key), keys, default)

  def get_nested([_ | _] = keyword, [key], default), do: Keyword.get(keyword, key, default)

  def get_nested([_ | _] = keyword, [key | keys], default),
    do: get_nested(Keyword.get(keyword, key), keys, default)

  def get_nested(_, _, default), do: default
end
