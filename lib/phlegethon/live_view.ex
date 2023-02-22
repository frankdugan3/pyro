# Original file: phoenix_live_view.ex from Phoenix LiveView (https://github.com/phoenixframework/phoenix_live_view/blob/master/lib/phoenix_live_view.ex)
# Modifications: Change references to Phoenix.LiveComponent and Phoenix.Component for compatibility reasons, stripped out everything that could be imported/delegated from original library.
# Copyright 2023 Frank Dugan III
# Licensed under the MIT license

defmodule Phlegethon.LiveView do
  @moduledoc ~S'''
  This is basically the same thing as `Phoenix.LiveView`, but imports `Phlegethon.LiveComponent` and `Phlegethon.Component` instead of `Phoenix.LiveComponent` and `Phoenix.Component` for proper validation of Phlegethon's extended features. Otherwise, there would be false warnings about undefined attributes, etc.

  ```
  use Phlegethon.LiveView
  ```

  > #### Note: {: .info}
  >
  > Please see the `Phoenix.LiveView` docs, as they will not be duplicated here.
  '''

  alias Phoenix.LiveView.Socket

  @type unsigned_params :: map

  @callback mount(
              params :: unsigned_params() | :not_mounted_at_router,
              session :: map,
              socket :: Socket.t()
            ) ::
              {:ok, Socket.t()} | {:ok, Socket.t(), keyword()}

  @callback render(assigns :: Socket.assigns()) :: Phoenix.LiveView.Rendered.t()

  @callback terminate(reason, socket :: Socket.t()) :: term
            when reason: :normal | :shutdown | {:shutdown, :left | :closed | term}

  @callback handle_params(unsigned_params(), uri :: String.t(), socket :: Socket.t()) ::
              {:noreply, Socket.t()}

  @callback handle_event(event :: binary, unsigned_params(), socket :: Socket.t()) ::
              {:noreply, Socket.t()} | {:reply, map, Socket.t()}

  @callback handle_call(msg :: term, {pid, reference}, socket :: Socket.t()) ::
              {:noreply, Socket.t()} | {:reply, term, Socket.t()}

  @callback handle_cast(msg :: term, socket :: Socket.t()) ::
              {:noreply, Socket.t()}

  @callback handle_info(msg :: term, socket :: Socket.t()) ::
              {:noreply, Socket.t()}

  @optional_callbacks mount: 3,
                      terminate: 2,
                      handle_params: 3,
                      handle_event: 3,
                      handle_call: 3,
                      handle_info: 2,
                      handle_cast: 2

  @doc false
  defmacro __using__(opts) do
    # Expand layout if possible to avoid compile-time dependencies
    opts =
      with true <- Keyword.keyword?(opts),
           {layout, template} <- Keyword.get(opts, :layout) do
        layout = Macro.expand(layout, %{__CALLER__ | function: {:__live__, 0}})
        Keyword.replace!(opts, :layout, {layout, template})
      else
        _ -> opts
      end

    quote bind_quoted: [opts: opts] do
      import Phlegethon.LiveView
      @behaviour Phlegethon.LiveView
      @before_compile Phoenix.LiveView.Renderer

      @phoenix_live_opts opts
      Module.register_attribute(__MODULE__, :phoenix_live_mount, accumulate: true)
      @before_compile Phlegethon.LiveView

      # Phlegethon.Component must come last so its @before_compile runs last
      use Phlegethon.Component, Keyword.take(opts, [:global_prefixes])
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    opts = Module.get_attribute(env.module, :phoenix_live_opts)

    layout =
      Phoenix.LiveView.Utils.normalize_layout(Keyword.get(opts, :layout, false), "use options")

    log =
      case Keyword.fetch(opts, :log) do
        {:ok, false} -> false
        {:ok, log} when is_atom(log) -> log
        :error -> :debug
        _ -> raise ArgumentError, ":log expects an atom or false, got: #{inspect(opts[:log])}"
      end

    phoenix_live_mount = Module.get_attribute(env.module, :phoenix_live_mount)
    lifecycle = Phoenix.LiveView.Lifecycle.mount(env.module, phoenix_live_mount)

    namespace =
      opts[:namespace] || env.module |> Module.split() |> Enum.take(1) |> Module.concat()

    name = env.module |> Atom.to_string() |> String.replace_prefix("#{namespace}.", "")
    container = opts[:container] || {:div, []}

    live = %{
      container: container,
      name: name,
      kind: :view,
      module: env.module,
      layout: layout,
      lifecycle: lifecycle,
      log: log
    }

    quote do
      @doc false
      def __live__ do
        unquote(Macro.escape(live))
      end
    end
  end

  @doc false
  defmacro on_mount(mod_or_mod_arg) do
    mod_or_mod_arg =
      if Macro.quoted_literal?(mod_or_mod_arg) do
        Macro.prewalk(mod_or_mod_arg, &expand_alias(&1, __CALLER__))
      else
        mod_or_mod_arg
      end

    quote do
      Module.put_attribute(
        __MODULE__,
        :phoenix_live_mount,
        Phoenix.LiveView.Lifecycle.on_mount(__MODULE__, unquote(mod_or_mod_arg))
      )
    end
  end

  defp expand_alias({:__aliases__, _, _} = alias, env),
    do: Macro.expand(alias, %{env | function: {:on_mount, 4}})

  defp expand_alias(other, _env), do: other

  @doc false
  defdelegate connected?(socket), to: Phoenix.LiveView
  @doc false
  defdelegate put_flash(socket, kind, msg), to: Phoenix.LiveView.Utils
  @doc false
  defdelegate clear_flash(socket), to: Phoenix.LiveView.Utils
  @doc false
  defdelegate clear_flash(socket, key), to: Phoenix.LiveView.Utils
  @doc false
  defdelegate push_event(socket, event, payload), to: Phoenix.LiveView.Utils
  @doc false
  defdelegate allow_upload(socket, name, options), to: Phoenix.LiveView.Upload
  @doc false
  defdelegate disallow_upload(socket, name), to: Phoenix.LiveView.Upload
  @doc false
  defdelegate cancel_upload(socket, name, entry_ref), to: Phoenix.LiveView.Upload
  @doc false
  defdelegate uploaded_entries(socket, name), to: Phoenix.LiveView.Upload
  @doc false
  defdelegate consume_uploaded_entries(socket, name, func), to: Phoenix.LiveView.Upload
  @doc false
  defdelegate consume_uploaded_entry(socket, entry, func), to: Phoenix.LiveView.Upload
  @doc false
  defdelegate redirect(socket, opts \\ []), to: Phoenix.LiveView
  @doc false
  defdelegate push_patch(socket, opts), to: Phoenix.LiveView
  @doc false
  defdelegate push_navigate(socket, opts), to: Phoenix.LiveView
  @doc false
  defdelegate push_redirect(socket, opts), to: Phoenix.LiveView
  @doc false
  defdelegate get_connect_params(socket), to: Phoenix.LiveView
  @doc false
  defdelegate get_connect_info(socket, key), to: Phoenix.LiveView
  @doc false
  defdelegate static_changed?(socket), to: Phoenix.LiveView
  @doc false
  defdelegate send_update(pid \\ self(), module, assigns), to: Phoenix.LiveView
  @doc false
  defdelegate send_update_after(pid \\ self(), module, assigns, time_in_milliseconds),
    to: Phoenix.LiveView

  @doc false
  defdelegate transport_pid(socket), to: Phoenix.LiveView
  @doc false
  defdelegate attach_hook(socket, name, stage, fun), to: Phoenix.LiveView.Lifecycle
  @doc false
  defdelegate detach_hook(socket, name, stage), to: Phoenix.LiveView.Lifecycle
  @doc false
  defdelegate stream(socket, name, items, opts \\ []), to: Phoenix.LiveView
  @doc false
  defdelegate stream_insert(socket, name, item, opts \\ []), to: Phoenix.LiveView
  @doc false
  defdelegate stream_delete(socket, name, item), to: Phoenix.LiveView
  @doc false
  defdelegate stream_delete_by_dom_id(socket, name, id), to: Phoenix.LiveView
end
