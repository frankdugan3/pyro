defmodule Pyro.Design.Macros do
  @moduledoc """
  Authoring macros for the `Pyro.Design` DSL.

  Each macro produces a `%Pyro.Design.Token{}` with its value parsed
  eagerly at compile time. Malformed inputs fail at compile of the
  authoring module, not at runtime. Imported automatically inside
  design, group, modifier, and context blocks.
  """

  @dtcg_shapes [
    color: %{kind: :scalar},
    dimension: %{kind: :scalar},
    duration: %{kind: :scalar},
    font_family: %{kind: :scalar},
    font_weight: %{kind: :scalar},
    cubic_bezier: %{kind: :scalar},
    number: %{kind: :scalar},
    stroke_style: %{
      kind: :mixed,
      fields: [
        dash_array: %{type: :list, required: false},
        line_cap: %{type: :atom, required: false}
      ]
    },
    border: %{
      kind: :composite,
      fields: [
        color: %{type: :color, required: true},
        width: %{type: :dimension, required: true},
        style: %{type: :stroke_style, required: true}
      ]
    },
    transition: %{
      kind: :composite,
      fields: [
        duration: %{type: :duration, required: true},
        delay: %{type: :duration, required: false},
        timing_function: %{type: :cubic_bezier, required: true}
      ]
    },
    shadow: %{
      kind: :composite,
      fields: [
        color: %{type: :color, required: true},
        offset_x: %{type: :dimension, required: true},
        offset_y: %{type: :dimension, required: true},
        blur: %{type: :dimension, required: true},
        spread: %{type: :dimension, required: true}
      ]
    },
    typography: %{
      kind: :composite,
      fields: [
        font_family: %{type: :font_family, required: true},
        font_size: %{type: :dimension, required: true},
        font_weight: %{type: :font_weight, required: true},
        line_height: %{type: :number, required: false},
        letter_spacing: %{type: :dimension, required: false}
      ]
    },
    gradient: %{
      kind: :composite_variadic,
      fields: [
        stop: %{type: :gradient_stop, required: true, variadic: true}
      ]
    }
  ]

  @doc "Returns the DSL shape metadata for every typed token macro."
  @spec __dtcg_shapes__() :: keyword(map())
  def __dtcg_shapes__, do: @dtcg_shapes

  @doc ~S'''
  DTCG `color` token. Accepts a CSS string or a `Color.t()` struct.

      iex> design = compile_design!(~s|color :bg, "#ffffff"|)
      iex> token_value(design, [:bg])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :bg,
        type: :color,
        value: %Color.SRGB{r: 1.0, g: 1.0, b: 1.0, alpha: nil},
        ref: nil,
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro color(name, input, opts \\ []) do
    build_token(name, :color, quote(do: Pyro.Design.Value.Color.parse!(unquote(input))), opts)
  end

  @doc ~S'''
  DTCG `dimension` token. Takes a numeric scalar and a `:px | :rem` unit.

      iex> design = compile_design!("dimension :xs, 0.25, :rem")
      iex> token_value(design, [:xs])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :xs,
        type: :dimension,
        value: {0.25, :rem},
        ref: nil,
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro dimension(name, scalar, unit, opts \\ []) do
    value_ast = quote(do: Pyro.Design.Value.Dimension.parse!({unquote(scalar), unquote(unit)}))
    build_token(name, :dimension, value_ast, opts)
  end

  @doc ~S'''
  DTCG `duration` token. Takes a numeric scalar and a `:ms | :s` unit.

      iex> design = compile_design!("duration :fast, 150, :ms")
      iex> token_value(design, [:fast])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :fast,
        type: :duration,
        value: {150.0, :ms},
        ref: nil,
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro duration(name, scalar, unit, opts \\ []) do
    value_ast = quote(do: Pyro.Design.Value.Duration.parse!({unquote(scalar), unquote(unit)}))
    build_token(name, :duration, value_ast, opts)
  end

  @doc ~S'''
  DTCG `fontFamily` token. Accepts a string or a list of strings.

      iex> design = compile_design!(~s|font_family :sans, ["Inter", "sans-serif"]|)
      iex> token_value(design, [:sans])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :sans,
        type: :font_family,
        value: ["Inter", "sans-serif"],
        ref: nil,
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro font_family(name, families, opts \\ []) do
    value_ast = quote(do: Pyro.Design.Value.FontFamily.parse!(unquote(families)))
    build_token(name, :font_family, value_ast, opts)
  end

  @doc ~S'''
  DTCG `fontWeight` token. Integer 1..1000 or a CSS alias atom.

      iex> design = compile_design!("font_weight :bold, 700")
      iex> token_value(design, [:bold])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :bold,
        type: :font_weight,
        value: 700,
        ref: nil,
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro font_weight(name, weight, opts \\ []) do
    value_ast = quote(do: Pyro.Design.Value.FontWeight.parse!(unquote(weight)))
    build_token(name, :font_weight, value_ast, opts)
  end

  @doc ~S'''
  DTCG `cubicBezier` token. A 4-tuple or 4-element list; x-coords in `[0, 1]`.

      iex> design = compile_design!("cubic_bezier :standard, {0.2, 0.0, 0.0, 1.0}")
      iex> token_value(design, [:standard])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :standard,
        type: :cubic_bezier,
        value: {0.2, 0.0, 0.0, 1.0},
        ref: nil,
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro cubic_bezier(name, points, opts \\ []) do
    value_ast = quote(do: Pyro.Design.Value.CubicBezier.parse!(unquote(points)))
    build_token(name, :cubic_bezier, value_ast, opts)
  end

  @doc ~S'''
  DTCG `number` token.

      iex> design = compile_design!("number :z_base, 10")
      iex> token_value(design, [:z_base])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :z_base,
        type: :number,
        value: 10.0,
        ref: nil,
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro number(name, n, opts \\ []) do
    value_ast = quote(do: Pyro.Design.Value.Number.parse!(unquote(n)))
    build_token(name, :number, value_ast, opts)
  end

  @doc ~S'''
  DTCG `strokeStyle` token.

  Scalar form accepts a predefined style: `:solid`, `:dashed`, `:dotted`, etc.

      iex> design = compile_design!("stroke_style :line, :dashed")
      iex> token_value(design, [:line])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :line,
        type: :stroke_style,
        value: "dashed",
        ref: nil,
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }

  Composite form accepts a do-block with `dash_array` and `line_cap`:

      iex> design = compile_design!(~S"""
      ...> stroke_style :custom do
      ...>   dash_array [{1, :px}, {0.5, :rem}]
      ...>   line_cap :round
      ...> end
      ...> """)
      iex> token_value(design, [:custom])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :custom,
        type: :stroke_style,
        value: %{dash_array: [{1.0, :px}, {0.5, :rem}], line_cap: :round},
        ref: nil,
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro stroke_style(name, input_or_do, opts \\ [])

  defmacro stroke_style(name, [do: block], _opts) do
    composite_stroke_style(name, block)
  end

  defmacro stroke_style(name, input, opts) do
    value_ast = quote(do: Pyro.Design.Value.StrokeStyle.parse!(unquote(input)))
    build_token(name, :stroke_style, value_ast, opts)
  end

  defp composite_stroke_style(name, block) do
    kw_ast = extract_keyword_stmts(block, [:dash_array, :line_cap])
    value_ast = quote(do: Pyro.Design.Value.StrokeStyle.parse!(unquote(kw_ast)))
    build_token(name, :stroke_style, value_ast, [])
  end

  @doc ~S'''
  DTCG `border` composite token.

      iex> design = compile_design!(~S"""
      ...> border :card do
      ...>   color "#e5e7eb"
      ...>   width 1, :px
      ...>   style :solid
      ...> end
      ...> """)
      iex> token_value(design, [:card])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :card,
        type: :border,
        value: %{
          width: {1.0, :px},
          color: %Color.SRGB{r: 0.8980392156862745, g: 0.9058823529411765, b: 0.9215686274509803, alpha: nil},
          style: "solid"
        },
        ref: nil,
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro border(name, do: block), do: composite(name, :border, block)

  @doc ~S'''
  DTCG `transition` composite token.

      iex> design = compile_design!(~S"""
      ...> transition :hover do
      ...>   duration 150, :ms
      ...>   delay 0, :ms
      ...>   timing_function 0.2, 0.0, 0.0, 1.0
      ...> end
      ...> """)
      iex> token_value(design, [:hover])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :hover,
        type: :transition,
        value: %{
          duration: {150.0, :ms},
          delay: {0.0, :ms},
          timing_function: {0.2, 0.0, 0.0, 1.0}
        },
        ref: nil,
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro transition(name, do: block), do: composite(name, :transition, block)

  @doc ~S'''
  DTCG `shadow` composite token. `description` and `deprecated` may
  also appear inside the do-block; they are hoisted onto the token
  rather than into the value.

      iex> design = compile_design!(~S"""
      ...> shadow :card do
      ...>   description "Card elevation shadow."
      ...>   color "#0003"
      ...>   offset_x 0, :px
      ...>   offset_y 1, :px
      ...>   blur 2, :px
      ...>   spread 0, :px
      ...> end
      ...> """)
      iex> token_value(design, [:card])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :card,
        type: :shadow,
        value: %{
          color: %Color.SRGB{r: 0.0, g: 0.0, b: 0.0, alpha: 0.2},
          offset_x: {0.0, :px},
          offset_y: {1.0, :px},
          blur: {2.0, :px},
          spread: {0.0, :px}
        },
        ref: nil,
        description: "Card elevation shadow.",
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro shadow(name, do: block), do: composite(name, :shadow, block)

  @doc ~S'''
  DTCG `typography` composite token.

      iex> design = compile_design!(~S"""
      ...> typography :display do
      ...>   font_family ["Inter"]
      ...>   font_size 3.0, :rem
      ...>   font_weight 800
      ...> end
      ...> """)
      iex> token_value(design, [:display])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :display,
        type: :typography,
        value: %{
          font_family: ["Inter"],
          font_size: {3.0, :rem},
          font_weight: 800
        },
        ref: nil,
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro typography(name, do: block), do: composite(name, :typography, block)

  @doc ~S'''
  DTCG `gradient` composite token. Each `stop` takes a color and a position in `[0, 1]`.

      iex> design = compile_design!(~S"""
      ...> gradient :sunset do
      ...>   stop "#ff7a00", 0.0
      ...>   stop "#ff0080", 1.0
      ...> end
      ...> """)
      iex> token_value(design, [:sunset])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :sunset,
        type: :gradient,
        value: [
          %{color: %Color.SRGB{r: 1.0, g: 0.47843137254901963, b: 0.0, alpha: nil}, position: 0.0},
          %{color: %Color.SRGB{r: 1.0, g: 0.0, b: 0.5019607843137255, alpha: nil}, position: 1.0}
        ],
        ref: nil,
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro gradient(name, do: block) do
    stops_ast = extract_stops(block)
    value_ast = quote(do: Pyro.Design.Value.Gradient.parse!(unquote(stops_ast)))
    build_token(name, :gradient, value_ast, [])
  end

  @doc ~S'''
  Declares a `$ref`-only token — an alias pointing at another token or group.

      iex> design = compile_design!(~S"""
      ...> color :brand, "#0066cc"
      ...> ref :primary, "#/brand"
      ...> """)
      iex> token_value(design, [:primary])
      %Pyro.Design.Token{
        __spark_metadata__: %Spark.Dsl.Entity.Meta{anno: nil, properties_anno: %{}},
        name: :primary,
        type: nil,
        value: nil,
        ref: %Pyro.Design.Reference{pointer: [:brand], kind: :pointer},
        description: nil,
        deprecated: false,
        extensions: %{},
        root?: false
      }
  '''
  defmacro ref(name, pointer, opts \\ []) do
    static = [ref: quote(do: Pyro.Design.Reference.parse!(unquote(pointer)))]
    combined = Keyword.merge(opts, static)

    quote do
      token unquote(name), unquote(combined)
    end
  end

  @doc """
  Declares a DTCG `$root` token inside a group. First arg is the `$type`;
  reserved name `:"$root"` and `root?: true` are auto-set.
  """
  defmacro root(type, input, opts \\ []) do
    value_ast = quote(do: Pyro.Design.Macros.parse_for_type!(unquote(type), unquote(input)))

    static = [type: type, value: value_ast, root?: true]
    combined = Keyword.merge(opts, static)

    quote do
      token :"$root", unquote(combined)
    end
  end

  @doc false
  def parse_for_type!(:color, input), do: Pyro.Design.Value.Color.parse!(input)
  def parse_for_type!(:dimension, input), do: Pyro.Design.Value.Dimension.parse!(input)
  def parse_for_type!(:duration, input), do: Pyro.Design.Value.Duration.parse!(input)
  def parse_for_type!(:font_family, input), do: Pyro.Design.Value.FontFamily.parse!(input)
  def parse_for_type!(:font_weight, input), do: Pyro.Design.Value.FontWeight.parse!(input)
  def parse_for_type!(:cubic_bezier, input), do: Pyro.Design.Value.CubicBezier.parse!(input)
  def parse_for_type!(:number, input), do: Pyro.Design.Value.Number.parse!(input)
  def parse_for_type!(:stroke_style, input), do: Pyro.Design.Value.StrokeStyle.parse!(input)
  def parse_for_type!(:border, input), do: Pyro.Design.Value.Border.parse!(input)
  def parse_for_type!(:transition, input), do: Pyro.Design.Value.Transition.parse!(input)
  def parse_for_type!(:shadow, input), do: Pyro.Design.Value.Shadow.parse!(input)
  def parse_for_type!(:gradient, input), do: Pyro.Design.Value.Gradient.parse!(input)
  def parse_for_type!(:typography, input), do: Pyro.Design.Value.Typography.parse!(input)

  defp build_token(name, type, value_ast, opts) do
    static = [type: type, value: value_ast]
    combined = Keyword.merge(opts, static)

    quote do
      token unquote(name), unquote(combined)
    end
  end

  defp composite(name, type, block) do
    fields =
      @dtcg_shapes
      |> Keyword.fetch!(type)
      |> Map.fetch!(:fields)

    allowed_keys = Enum.map(fields, fn {k, _} -> k end)
    kw_ast = extract_keyword_stmts(block, allowed_keys)
    meta_opts = extract_meta_opts(block)

    parser = Module.concat([Pyro.Design.Value, Macro.camelize(Atom.to_string(type))])
    value_ast = quote(do: unquote(parser).parse!(unquote(kw_ast)))
    build_token(name, type, value_ast, meta_opts)
  end

  defp extract_meta_opts(block) do
    stmts =
      case block do
        {:__block__, _, list} -> list
        single -> [single]
      end

    Enum.flat_map(stmts, fn
      {:description, _, [value]} -> [description: value]
      {:deprecated, _, [value]} -> [deprecated: value]
      _ -> []
    end)
  end

  defp extract_keyword_stmts(block, allowed) do
    stmts =
      case block do
        {:__block__, _, list} -> list
        single -> [single]
      end

    pairs =
      Enum.flat_map(stmts, fn
        {key, _meta, args} when is_atom(key) and is_list(args) ->
          if key in allowed do
            [{key, pack_args(args)}]
          else
            []
          end

        _ ->
          []
      end)

    quote do
      unquote(pairs)
    end
  end

  defp extract_stops(block) do
    stmts =
      case block do
        {:__block__, _, list} -> list
        single -> [single]
      end

    stops =
      Enum.flat_map(stmts, fn
        {:stop, _meta, [color_arg, position_arg]} ->
          [[color: color_arg, position: position_arg]]

        _ ->
          []
      end)

    quote do
      unquote(stops)
    end
  end

  defp pack_args([single]), do: single
  defp pack_args([a, b]), do: quote(do: {unquote(a), unquote(b)})

  defp pack_args([a, b, c, d]),
    do: quote(do: {unquote(a), unquote(b), unquote(c), unquote(d)})

  defp pack_args(args), do: args
end
