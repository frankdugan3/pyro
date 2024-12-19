defmodule Pyro.Component.Template do
  @moduledoc """
  Templating for `Pyro`.

  > #### Warning: {: .warning}
  >
  > These sigils/types/functions/schemas exist specifically to enable deferring compilation of templates until a later time. This enables Pyro to merge component DSLs and do custom validation. They should not be used outside `Pyro` DSL.
  """

  @type t :: %__MODULE__{
          kind: :eex,
          file: String.t(),
          module: atom(),
          line: non_neg_integer(),
          indentation: non_neg_integer(),
          source: String.t(),
          rendered: String.t()
        }

  defstruct [
    :kind,
    :file,
    :module,
    :line,
    :indentation,
    :source,
    :rendered
  ]

  @doc type: :macro
  defmacro sigil_E({:<<>>, meta, [source]}, []) do
    # Multi-line sigils have indentation key, offset by 1
    line = __CALLER__.line + if(meta[:indentation], do: 1, else: 0)
    # Single-line sigils have no indentation, offset by column + sigil characters
    indentation = meta[:indentation] || meta[:column] + 2

    Macro.escape(%__MODULE__{
      kind: :eex,
      file: Path.relative_to_cwd(__CALLER__.file),
      module: __CALLER__.module,
      line: line,
      indentation: indentation,
      source: source
    })
  end

  @template_schema {:struct, __MODULE__}

  @doc """
  Schema for `sigil_E/2`. It accepts `opts` to allow building more specialized schemas without boilerplate.

  #### Examples

  ```elixir
  sigile_schema([
    docs: "EEx template for CSS class `base_name`; passed `vars` and `scope`."
  ])
  ```
  """
  @doc type: :dsl_schema
  def sigile_schema(opts \\ []) do
    Keyword.merge(
      [
        type: {:or, [:string, @template_schema]},
        snippet: ~S'''
        ~E"""
        ${0}
        """
        ''',
        doc: "EEx template that will be rendered at at compile time."
      ],
      opts
    )
  end

  @typedoc """
  A variable or scope reference to be expanded at compile time.
  """
  @type expand_var :: {:var | :scope, atom()}

  @doc """
  Schema for a variable or scope reference to be expanded at compile time. It accepts `opts` to allow building more specialized schemas without  boilerplate.
  """
  def expand_var_schema(_opts \\ []) do
    {:or, [{:tagged_tuple, :var, :atom}, {:tagged_tuple, :scope, :atom}]}
  end

  @doc """
  Documents a type that accepts variables. Append it to the type's docs to ensure all variables are consistently documented.
  """
  def expand_var_doc do
    "`{:var, :key}`: a variable; `{:scope, :key}`: value from current scope."
  end

  @doc """
  A simple template to automatically generate headless BEM templates from configured variants.
  """
  def headless_bem_template do
    ~E"""
    <% import Pyro.Component.Template, only: [format_properties: 2]
    %>.<%= base_class %> {<%=
      format_properties(vars, [:headless_bem, "block"])
    %>}<%= for {key, values} <- variants do %><%= for value <- values do %>
    .<%= base_class %>--<%= value %> {<%=
      format_properties(vars, [:headless_bem, "#{key}:#{value}"])
    %>}<% end %><% end %>
    """
  end
end
