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

  @doc false
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(Pyro.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(Pyro.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
