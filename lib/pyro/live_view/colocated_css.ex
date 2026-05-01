if Code.ensure_loaded?(Phoenix.LiveView.ColocatedCSS) do
  defmodule Pyro.LiveView.ColocatedCSS do
    @moduledoc """
    A `Phoenix.LiveView.ColocatedCSS` callback that routes colocated
    `<style>` blocks through a Pyro design.

    Each wrapper module names its design explicitly:

        defmodule MyAppWeb.ColocatedCSS do
          use Pyro.LiveView.ColocatedCSS, design: MyAppWeb.Design
        end

        # in any HEEx component
        ~H\"\"\"
        <style :type={MyAppWeb.ColocatedCSS}>
          .btn { color: $color.brand.500; }
          @media (min-width: $breakpoint.md) { .btn { padding: $space.lg; } }
        </style>
        \"\"\"

    At each component's compile, the `<style>` body is processed:

      * `$token.path` references resolve to `var(--<namespace>-<dashed-path>)`,
        with the namespace coming from the wrapper's design's `:config > namespace`.
      * References inside `@media (...)` query conditions resolve to the
        token's literal value, since `var()` is invalid there.
      * Every reference is validated against the design's token tree.
        Unknown refs raise at compile time, listing every offence.
      * Raw `var(--<namespace>-…)` calls in the source raise at compile time —
        all design lookups must go through `$token.path` so the system
        can validate and substitute them.

    Libraries that ship colocated CSS define their own wrapper baked
    against their own design module, so the library's components compile
    and validate independently of any consumer-app configuration.
    """

    @doc false
    defmacro __using__(opts) do
      design =
        Keyword.get(opts, :design) ||
          raise CompileError,
            description: """
            `use Pyro.LiveView.ColocatedCSS` requires a `:design` option:

                use Pyro.LiveView.ColocatedCSS, design: MyAppWeb.Design

            The design module is baked into the wrapper at compile time, so
            every wrapper validates colocated CSS against an explicit token
            vocabulary and is independent of consumer-app configuration.
            """

      quote do
        use Phoenix.LiveView.ColocatedCSS

        @pyro_design unquote(design)

        @impl Phoenix.LiveView.ColocatedCSS
        def transform(tag, attrs, css, meta) do
          Pyro.LiveView.ColocatedCSS.__transform__(tag, attrs, css, meta, @pyro_design)
        end
      end
    end

    @doc false
    def __transform__("style", _attrs, css, meta, design) when is_atom(design) do
      tokens = Pyro.Design.Info.tokens(design)
      namespace = Pyro.Design.Info.namespace(design)

      check_no_raw_namespaced_vars!(css, namespace, meta)
      check_refs!(css, tokens, design, meta)

      {:ok, Pyro.Design.CSS.resolve_in_css(css, design), []}
    end

    defp check_no_raw_namespaced_vars!(css, namespace, meta) do
      regex = ~r/var\(\s*--#{Regex.escape(namespace)}-[^)]+\)/

      case Regex.scan(regex, css) do
        [] ->
          :ok

        matches ->
          offences = matches |> Enum.map(fn [m] -> "  #{m}" end) |> Enum.join("\n")

          raise CompileError,
            file: meta.file,
            line: meta.line,
            description: """
            raw `var(--#{namespace}-…)` is not allowed in colocated CSS routed through Pyro.LiveView.ColocatedCSS.

            Use `$token.path` references against the design instead — they validate
            against the token tree and resolve to the design's namespace.

            Offending occurrences:
            #{offences}
            """
      end
    end

    defp check_refs!(css, tokens, design, meta) do
      missing =
        css
        |> Pyro.Design.CSS.walk_refs()
        |> Enum.reject(fn %{path: path} -> Map.has_key?(tokens, path) end)

      case missing do
        [] ->
          :ok

        refs ->
          listed =
            refs |> Enum.map(fn %{raw: raw} -> "  #{raw}" end) |> Enum.uniq() |> Enum.join("\n")

          raise CompileError,
            file: meta.file,
            line: meta.line,
            description: """
            Pyro.LiveView.ColocatedCSS: unknown design token references.

            Design: #{inspect(design)}

            Unresolved references:
            #{listed}
            """
      end
    end
  end
end
