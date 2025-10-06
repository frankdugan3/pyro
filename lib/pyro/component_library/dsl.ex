# quokka:skip-module-reordering
defmodule Pyro.ComponentLibrary.Dsl do
  @moduledoc false

  defmodule Prop do
    @moduledoc false
    @type t :: %__MODULE__{
            default: any(),
            doc: binary() | nil,
            examples: list() | nil,
            name: atom(),
            required: boolean(),
            slot: atom() | nil,
            type:
              :any
              | :string
              | :atom
              | :boolean
              | :integer
              | :float
              | :list
              | :map
              | module(),
            values: list() | nil
          }

    # quokka:sort
    defstruct [
      :default,
      :doc,
      :examples,
      :include,
      :name,
      :required,
      :slot,
      :type,
      :values,
      __spark_metadata__: nil
    ]
  end

  @prop %Spark.Dsl.Entity{
    args: [:name, :type],
    describe: """
    Declare/extend a component prop.
    """,
    name: :prop,
    # quokka:sort
    schema: [
      default: [doc: "default value for the prop", type: :any],
      doc: [type: :string, doc: "documentation for the prop"],
      examples: [
        type: {:wrap_list, :any},
        doc: "document a non-exhaustive list of accepted values"
      ],
      include: [type: {:wrap_list, :string}, doc: "extra global attributes to include"],
      name: [type: :atom, required: true, doc: "name of the prop"],
      required: [type: :boolean, doc: "marks prop as required"],
      type: [
        type:
          {:or,
           [
             :module,
             {
               :one_of,
               [:any, :string, :atom, :boolean, :integer, :float, :list, :map, :global]
             }
           ]},
        required: true,
        doc: "type of the prop"
      ],
      values: [type: {:list, :any}, doc: "exhaustive list of accepted values"]
    ],
    target: __MODULE__.Prop
  }

  defmodule Global do
    @moduledoc false
    @type t :: %__MODULE__{
            default: any(),
            doc: String.t() | nil,
            include: list(String.t()) | nil,
            name: atom(),
            skip_template_validation?: boolean()
          }

    # quokka:sort
    defstruct [
      :default,
      :doc,
      :include,
      :name,
      :skip_template_validation?,
      __spark_metadata__: nil
    ]
  end

  @global %Spark.Dsl.Entity{
    args: [:name],
    describe: """
    Declare/extend a global attribute prop.
    """,
    name: :global,
    # quokka:sort
    schema: [
      default: [doc: "default value for the prop", type: :any],
      doc: [doc: "documentation for the prop", type: :string],
      include: [type: {:wrap_list, :string}, doc: "extra global attributes to include"],
      name: [type: :atom, required: true, doc: "name of the prop"],
      skip_template_validation?: [doc: "skip validating exists in ~H template", type: :boolean]
    ],
    target: __MODULE__.Global
  }

  defmodule Variant do
    @moduledoc false
    @type t :: %__MODULE__{name: atom()}

    # quokka:sort
    defstruct [:name, __spark_metadata__: nil]
  end

  @variant %Spark.Dsl.Entity{
    args: [:name],
    describe: """
    Declare a prop constrained to a theme variant.
    """,
    name: :variant,
    # quokka:sort
    schema: [
      name: [
        doc: "name of the prop",
        required: true,
        type: :atom
      ]
    ],
    target: __MODULE__.Variant
  }

  defmodule Calc do
    @moduledoc false
    @type t :: %__MODULE__{calculation: (map() -> any()), name: atom()}

    # quokka:sort
    defstruct [:calculation, :name, __spark_metadata__: nil]
  end

  @calc %Spark.Dsl.Entity{
    args: [:name, :calculation],
    describe: """
    Declare a calculation.
    """,
    name: :calc,
    # quokka:sort
    schema: [
      calculation: [
        doc: "arity-1 function that recieves `assigns`, setting the value on render",
        type: {:fun, [:map], :any}
      ],
      name: [
        type: :atom,
        required: true,
        doc: "name of the assign"
      ]
    ],
    snippet: """
    calc :${1}, fn assigns ->
      ${0}
    end
    """,
    target: __MODULE__.Calc
  }

  defmodule Slot do
    @moduledoc false

    alias Pyro.ComponentLibrary.Dsl

    @type t :: %__MODULE__{
            attrs: list(Dsl.Prop.t()),
            doc: String.t() | nil,
            name: atom(),
            required: boolean(),
            validate_attrs: boolean()
          }

    # quokka:sort
    defstruct [
      :attrs,
      :doc,
      :name,
      :required,
      :validate_attrs,
      __spark_metadata__: nil
    ]
  end

  @slot %Spark.Dsl.Entity{
    args: [:name],
    describe: """
    Declare/extend a component slot.
    """,
    entities: [
      attrs: [@prop]
    ],
    name: :slot,
    # quokka:sort
    schema: [
      doc: [
        doc: "documentation for the slot",
        type: :string
      ],
      name: [
        type: :atom,
        required: true,
        doc: "name of the slot"
      ],
      required: [
        type: :boolean,
        doc: "marks slot as required"
      ],
      validate_attrs: [
        type: :boolean,
        doc: "validate attributes passed to slot (default: `true`)"
      ]
    ],
    target: __MODULE__.Slot
  }

  defmodule Render do
    @moduledoc false

    alias Pyro.ComponentLibrary.Dsl

    @type t :: %__MODULE__{args: any(), expr: any(), template: String.t()}

    # quokka:sort
    defstruct [:args, :expr, :template, __spark_metadata__: nil]

    def transform(%__MODULE__{args: args, expr: [do: expr]} = entity) do
      sigils =
        Macro.prewalk(expr, [], fn
          {:sigil_H, meta, [{:<<>>, string_meta, [content]}, _opts]} = node, acc ->
            {node, [{content, meta, string_meta} | acc]}

          node, acc ->
            {node, acc}
        end)
        |> elem(1)
        |> Enum.reverse()

      if sigils != [] && !has_assigns?(args, :assigns) do
        raise Spark.Error.DslError,
          message: "~H requires a variable named \"assigns\" to exist and be set to a map"
      end

      file = entity.__spark_metadata__.anno[:file]

      for {content, meta, string_meta} <- sigils do
        opts = [
          file: file,
          line: string_meta[:line] + 1,
          source_offset: meta[:line],
          indentation: string_meta[:indentation] || 0
        ]

        ast = Pyro.HEEx.AST.parse!(content, opts)
        tally = Pyro.HEEx.tally_attributes(ast, "pyro-component")

        root_node =
          ast.nodes
          |> Enum.find(fn node ->
            node.__struct__ in [Pyro.HEEx.AST.Component, Pyro.HEEx.AST.Element]
          end)

        total_count =
          tally
          |> Map.get("pyro-component", %{})
          |> Map.values()
          |> Enum.sum()

        if total_count != 1 do
          raise Pyro.HEEx.AST.ParseError,
            file: opts[:file],
            line: root_node.line,
            column: root_node.column,
            source: content,
            indentation: opts[:indentation],
            source_offset: opts[:source_offset],
            message: "The attribute \"pyro-component\" must appear exactly once per sigil"
        end
      end

      {:ok, %{entity | expr: expr}}
    end

    defp has_assigns?(ast, var_name) when is_atom(var_name) do
      Macro.prewalk(ast, false, fn
        {^var_name, _, context} = node, _acc when is_atom(context) or is_nil(context) ->
          {node, true}

        node, acc ->
          {node, acc}
      end)
      |> elem(1)
    end
  end

  @render %Spark.Dsl.Entity{
    args: [:args, :expr],
    describe: """
    """,
    imports: [Pyro.ComponentLibrary.TemplateHelpers],
    name: :render,
    # quokka:sort
    schema: [
      args: [required: true, type: :quoted],
      expr: [type: :quoted, required: true]
    ],
    snippet: ~S[
      render assigns do
        ~H"""
        <${1:div} pyro-component>
          ${0}
        </${1}>
        """
      end
      ],
    target: __MODULE__.Render,
    transform: {__MODULE__.Render, :transform, []}
  }

  defmodule Component do
    @moduledoc false

    alias Pyro.ComponentLibrary.Dsl

    @type t :: %__MODULE__{
            assigns: list(Dsl.Prop.t() | Dsl.Global.t() | Dsl.Calc.t() | Dsl.Variant.t()),
            doc: String.t() | nil,
            name: atom(),
            private?: boolean(),
            render: list(Dsl.Render.t()),
            slots: list(Dsl.Slot.t())
          }

    # quokka:sort
    defstruct [
      :assigns,
      :doc,
      :name,
      :private?,
      :render,
      :slots,
      __spark_metadata__: nil
    ]
  end

  # quokka:sort
  @shared_component_schema [
    doc: [
      type: :string,
      doc: "documentation for the component"
    ],
    name: [
      type: :atom,
      required: true,
      doc: "name of the component"
    ]
  ]

  # quokka:sort
  @shared_component_entities [
    assigns: [@calc, @global, @prop, @variant],
    render: [@render],
    slots: [@slot]
  ]

  @component %Spark.Dsl.Entity{
    args: [:name],
    describe: """
    Declare/extend a component.
    """,
    entities: @shared_component_entities,
    name: :component,
    schema:
      @shared_component_schema ++
        [
          private?: [
            type: :boolean,
            doc: "mark the component as private (default: `false`)"
          ]
        ],
    target: __MODULE__.Component
  }

  defmodule LiveComponent do
    @moduledoc false

    alias Pyro.ComponentLibrary.Dsl

    @type t :: %__MODULE__{
            assigns: list(Dsl.Prop.t() | Dsl.Global.t() | Dsl.Calc.t() | Dsl.Variant.t()),
            components: list(Dsl.Component.t()),
            doc: binary() | nil,
            name: atom(),
            slots: list(Dsl.Slot.t())
          }

    # quokka:sort
    defstruct [
      :assigns,
      :components,
      :doc,
      :name,
      :private?,
      :slots,
      __spark_metadata__: nil
    ]
  end

  live_component = %Spark.Dsl.Entity{
    args: [:name],
    describe: """
    Declare/extend a live component.
    """,
    entities:
      @shared_component_entities ++
        [
          components: [@component]
        ],
    name: :live_component,
    schema: @shared_component_schema,
    target: __MODULE__.LiveComponent
  }

  @components %Spark.Dsl.Section{
    describe: """
    List of components to declare/extend.
    """,
    entities: [@component],
    name: :components,
    top_level?: true
  }

  defmodule ThemeProperty do
    @moduledoc false
    # quokka:sort
    defstruct [:default, :doc, :name, :tokens, :variants, __spark_metadata__: nil]
  end

  @token_type {:one_of, ~w[color size]a}
  @theme_property %Spark.Dsl.Entity{
    args: [:name, {:optional, :type}],
    describe: """
    Declare/extend a theme property.
    """,
    name: :theme,
    # quokka:sort
    schema: [
      default: [
        doc: "default variant",
        type: :atom
      ],
      doc: [
        type: :string,
        doc: "documentation for the component"
      ],
      name: [
        type: :atom,
        required: true,
        doc: "name of the property"
      ],
      tokens: [
        type: {:list, {:or, [:atom, {:tuple, [:atom, @token_type]}]}},
        doc: "tokens of this property"
      ],
      type: [
        type: @token_type,
        default: :color,
        doc: "default type of tokens"
      ],
      variants: [
        type: {:list, :atom},
        doc: "variants of this property"
      ]
    ],
    target: __MODULE__.ThemeProperty
  }

  @theme_properties %Spark.Dsl.Section{
    describe: """
    List of theme properties to declare/extend.
    """,
    entities: [@theme_property],
    name: :theme_properties,
    top_level?: true
  }

  @transformers [
    __MODULE__.Transformer.MergeComponents,
    __MODULE__.Transformer.ApplyHooks
  ]

  @verifiers []

  @sections [@theme_properties, @components]

  use Spark.Dsl.Extension,
    sections: @sections,
    transformers: @transformers,
    verifiers: @verifiers
end
