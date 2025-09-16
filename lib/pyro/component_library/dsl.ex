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

    defstruct [
      :default,
      :doc,
      :examples,
      :include,
      :name,
      :required,
      :slot,
      :type,
      :values
    ]
  end

  @prop %Spark.Dsl.Entity{
    describe: """
    Declare/extend a component prop.
    """,
    name: :prop,
    schema: [
      default: [type: :any, doc: "default value for the prop"],
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
    target: __MODULE__.Prop,
    args: [:name, :type]
  }

  defmodule Global do
    @moduledoc false
    @type t :: %__MODULE__{
            name: atom(),
            doc: String.t() | nil,
            include: list(String.t()) | nil
          }

    defstruct [:include, :name, :doc]
  end

  @global %Spark.Dsl.Entity{
    describe: """
    Declare/extend a global attribute prop.
    """,
    name: :global,
    schema: [
      doc: [type: :string, doc: "documentation for the prop"],
      include: [type: {:wrap_list, :string}, doc: "extra global attributes to include"],
      name: [type: :atom, required: true, doc: "name of the prop"]
    ],
    target: __MODULE__.Global,
    args: [:name]
  }

  defmodule Variant do
    @moduledoc false
    @type t :: %__MODULE__{
            name: atom()
          }

    defstruct [
      :name
    ]
  end

  @variant %Spark.Dsl.Entity{
    describe: """
    Declare a prop constrained to a theme variant.
    """,
    name: :variant,
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "name of the prop"
      ]
    ],
    target: __MODULE__.Variant,
    args: [:name]
  }

  defmodule Calc do
    @moduledoc false
    @type t :: %__MODULE__{
            calculation: (map() -> any()),
            name: atom()
          }

    defstruct [
      :calculation,
      :name
    ]
  end

  @calc %Spark.Dsl.Entity{
    describe: """
    Declare a calculation.
    """,
    name: :calc,
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "name of the assign"
      ],
      calculation: [
        type: {:fun, [:map], :any},
        doc: "arity-1 function that recieves `assigns`, setting the value on render"
      ]
    ],
    target: __MODULE__.Calc,
    args: [:name, :calculation],
    snippet: """
    calc :${1}, fn assigns ->
      ${0}
    end
    """
  }

  defmodule Slot do
    @moduledoc false

    alias Pyro.ComponentLibrary.Dsl

    @type t :: %__MODULE__{
            doc: String.t() | nil,
            name: atom(),
            attrs: list(Dsl.Prop.t()),
            required: boolean(),
            validate_attrs: boolean()
          }

    defstruct [
      :doc,
      :name,
      :attrs,
      :required,
      :validate_attrs
    ]
  end

  @slot %Spark.Dsl.Entity{
    describe: """
    Declare/extend a component slot.
    """,
    name: :slot,
    schema: [
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
      ],
      doc: [
        type: :string,
        doc: "documentation for the slot"
      ]
    ],
    target: __MODULE__.Slot,
    args: [:name],
    entities: [
      attrs: [@prop]
    ]
  }

  defmodule Render do
    @moduledoc false

    alias Pyro.ComponentLibrary.Dsl

    @type t :: %__MODULE__{
            args: any(),
            expr: any(),
            template: String.t()
          }

    defstruct [
      :args,
      :expr,
      :template
    ]
  end

  @render %Spark.Dsl.Entity{
    describe: """
    """,
    name: :render,
    schema: [
      args: [type: :quoted, required: true],
      expr: [type: :quoted, required: true]
    ],
    target: __MODULE__.Render,
    args: [:args, :expr],
    imports: [Pyro.ComponentLibrary.TemplateHelpers],
    transform: {Pyro.ComponentLibrary.TemplateHelpers, :transform_component_render, []},
    snippet: ~S[
      render assigns do
        ~H"""
        <div pyro-class>
          ${0}
        </div>
        """
      end
      ]
  }

  defmodule Component do
    @moduledoc false

    alias Pyro.ComponentLibrary.Dsl

    @type t :: %__MODULE__{
            classes: list(atom()),
            doc: String.t() | nil,
            name: atom(),
            private?: boolean(),
            assigns: list(Dsl.Prop.t() | Dsl.Global.t() | Dsl.Calc.t() | Dsl.Variant.t()),
            slots: list(Dsl.Slot.t()),
            render: list(Dsl.Render.t())
          }

    defstruct [
      :classes,
      :doc,
      :name,
      :private?,
      :assigns,
      :slots,
      :render
    ]
  end

  @shared_component_schema [
    classes: [type: {:wrap_list, :atom}, doc: "list of class props", default: [:class]],
    name: [
      type: :atom,
      required: true,
      doc: "name of the component"
    ],
    doc: [
      type: :string,
      doc: "documentation for the component"
    ]
  ]

  @shared_component_entities [
    assigns: [@prop, @global, @variant, @calc],
    slots: [@slot],
    render: [@render]
  ]

  @component %Spark.Dsl.Entity{
    describe: """
    Declare/extend a component.
    """,
    name: :component,
    schema:
      @shared_component_schema ++
        [
          private?: [
            type: :boolean,
            doc: "mark the component as private (default: `false`)"
          ]
        ],
    target: __MODULE__.Component,
    args: [:name],
    entities: @shared_component_entities
  }

  defmodule LiveComponent do
    @moduledoc false

    alias Pyro.ComponentLibrary.Dsl

    @type t :: %__MODULE__{
            classes: list(atom()),
            components: list(Dsl.Component.t()),
            doc: binary() | nil,
            name: atom(),
            assigns: list(Dsl.Prop.t() | Dsl.Global.t() | Dsl.Calc.t() | Dsl.Variant.t()),
            slots: list(Dsl.Slot.t())
          }

    defstruct [
      :assigns,
      :classes,
      :components,
      :doc,
      :name,
      :private?,
      :slots
    ]
  end

  live_component = %Spark.Dsl.Entity{
    describe: """
    Declare/extend a live component.
    """,
    name: :live_component,
    schema: @shared_component_schema,
    target: __MODULE__.LiveComponent,
    args: [:name],
    entities:
      @shared_component_entities ++
        [
          components: [@component]
          # template: [@template]
          # handle_async: [handle_async],
          # handle_event: [handle_event],
          # mount: [mount],
          # update: [update],
          # update_many: [update_many]
        ]
  }

  @components %Spark.Dsl.Section{
    name: :components,
    top_level?: true,
    describe: """
    List of components to declare/extend.
    """,
    entities: [
      @component
      # live_component
    ]
  }

  defmodule ThemeProperty do
    @moduledoc false
    defstruct [:name, :default, :variants, :tokens, :doc]
  end

  @token_type {:one_of, ~w[color size]a}
  @theme_property %Spark.Dsl.Entity{
    name: :theme,
    describe: """
    Declare/extend a theme property.
    """,
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "name of the property"
      ],
      type: [
        type: @token_type,
        default: :color,
        doc: "default type of tokens"
      ],
      variants: [
        type: {:list, :atom},
        doc: "variants of this property"
      ],
      tokens: [
        type: {:list, {:or, [:atom, {:tuple, [:atom, @token_type]}]}},
        doc: "tokens of this property"
      ],
      default: [
        type: :atom,
        doc: "default variant"
      ],
      doc: [
        type: :string,
        doc: "documentation for the component"
      ]
    ],
    target: __MODULE__.ThemeProperty,
    args: [:name, {:optional, :type}]
  }

  @theme_properties %Spark.Dsl.Section{
    top_level?: true,
    describe: """
    List of theme properties to declare/extend.
    """,
    name: :theme_properties,
    entities: [@theme_property]
  }

  @transformers [
    Pyro.Transformer.MergeComponents,
    Pyro.Transformer.CompileComponents
  ]

  # verifiers = [Pyro.Verifier.ImplementsCssStrategies]
  @verifiers []

  @sections [@theme_properties, @components]

  use Spark.Dsl.Extension,
    sections: @sections,
    transformers: @transformers,
    verifiers: @verifiers
end
