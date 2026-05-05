defmodule Pyro.Design.Info do
  @moduledoc """
  Runtime introspection for compiled `Pyro.Design` modules.

  The primary shape is a **path-keyed tree** of DTCG groups, tokens,
  modifiers, and contexts. Paths are lists of atoms — e.g.
  `[:color, :brand, :"500"]` for a token at the leaf of nested groups.
  """

  alias Pyro.Design.{Context, Group, Icon, Modifier, Reference, Token}
  alias Pyro.Design.Value.Color

  @doc "Returns the root `%Pyro.Design.Group{}` of this design."
  @spec tree(module()) :: Group.t() | nil
  def tree(design), do: Spark.Dsl.Extension.get_persisted(design, :design_tree)

  @doc "Returns the token or group at a path, or nil."
  @spec at(module(), [atom()]) :: Token.t() | Group.t() | nil
  def at(design, path) when is_list(path) do
    case tokens(design) do
      %{^path => token} ->
        token

      _ ->
        groups = Spark.Dsl.Extension.get_persisted(design, :design_group_paths, %{})
        Map.get(groups, path)
    end
  end

  @doc "Returns the flat `%{path => token}` map of all DTCG tokens."
  @spec tokens(module()) :: %{[atom()] => Token.t()}
  def tokens(design), do: Spark.Dsl.Extension.get_persisted(design, :design_token_paths, %{})

  @doc "Returns `%{path => dtcg_type_atom}` for every token, with inheritance resolved."
  @spec type_map(module()) :: %{[atom()] => atom()}
  def type_map(design), do: Spark.Dsl.Extension.get_persisted(design, :design_type_map, %{})

  @doc "Returns `%{from_path => %Pyro.Design.Reference{}}` for every `$ref` and `$extends`."
  @spec refs(module()) :: %{[atom()] => Reference.t()}
  def refs(design), do: Spark.Dsl.Extension.get_persisted(design, :design_refs, %{})

  @doc "Returns the flat `%{path => %Pyro.Design.Modifier{}}` map of all modifiers."
  @spec modifiers(module()) :: %{[atom()] => Modifier.t()}
  def modifiers(design),
    do: Spark.Dsl.Extension.get_persisted(design, :design_modifier_paths, %{})

  @doc "Returns the flat `%{path => %Pyro.Design.Context{}}` map of all contexts."
  @spec contexts(module()) :: %{[atom()] => Context.t()}
  def contexts(design), do: Spark.Dsl.Extension.get_persisted(design, :design_context_paths, %{})

  @doc "Returns the DTCG `$type` atoms supported by the DSL."
  @spec types() :: [atom()]
  def types, do: Token.types()

  @doc "Returns the 14 DTCG color space atoms."
  @spec color_spaces() :: [atom()]
  def color_spaces, do: Color.dtcg_color_spaces()

  @doc "CSS custom-property namespace."
  @spec namespace(module()) :: String.t()
  def namespace(design), do: Spark.Dsl.Extension.get_opt(design, [:config], :namespace)

  @doc "Raw Tailwind preamble CSS, or `nil`."
  @spec tailwind_preamble(module()) :: String.t() | nil
  def tailwind_preamble(design),
    do: Spark.Dsl.Extension.get_opt(design, [:config], :tailwind_preamble)

  @doc "Blocks declared under `config > base_layer` — `Selector` and `Raw` entities in declaration order."
  @spec base_layer_blocks(module()) :: [Pyro.Design.Selector.t() | Pyro.Design.Raw.t()]
  def base_layer_blocks(design),
    do: Spark.Dsl.Extension.get_entities(design, [:config, :base_layer])

  @doc "Output path for the generated CSS file, or `nil`."
  @spec css_output(module()) :: String.t() | nil
  def css_output(design), do: Spark.Dsl.Extension.get_persisted(design, :css_output)

  @doc "Output path for the generated DTCG JSON file, or `nil`."
  @spec json_output(module()) :: String.t() | nil
  def json_output(design), do: Spark.Dsl.Extension.get_persisted(design, :json_output)

  @doc "Whether the (future) CSS generator should emit Tailwind v4 directives."
  @spec support_tailwind?(module()) :: boolean()
  def support_tailwind?(design),
    do: Spark.Dsl.Extension.get_persisted(design, :support_tailwind?, false)

  @doc "Whether the (future) CSS generator should emit a `@layer base` block."
  @spec manage_base_layer?(module()) :: boolean()
  def manage_base_layer?(design),
    do: Spark.Dsl.Extension.get_persisted(design, :manage_base_layer?, false)

  @doc "Whether the writer should emit a Claude Code skill for this design under `.claude/skills/`."
  @spec generate_skills?(module()) :: boolean()
  def generate_skills?(design),
    do: Spark.Dsl.Extension.get_persisted(design, :generate_skills?, false)

  @doc "All declared icons."
  @spec icons(module()) :: [Icon.t()]
  def icons(design), do: Spark.Dsl.Extension.get_entities(design, [:icons])

  @doc "Single icon by name, or nil."
  @spec icon(module(), atom()) :: Icon.t() | nil
  def icon(design, name), do: Enum.find(icons(design), &(&1.name == name))

  @doc "Icon names in declaration order."
  @spec icon_names(module()) :: [atom()]
  def icon_names(design), do: Enum.map(icons(design), & &1.name)

  @doc "`%{icon_name => svg_string}` persisted map."
  @spec icon_map(module()) :: %{atom() => String.t()}
  def icon_map(design), do: Spark.Dsl.Extension.get_persisted(design, :design_icon_map, %{})
end
