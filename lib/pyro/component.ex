hook = %Spark.Dsl.Entity{
  describe: """
  Declare/extend a JS hook.
  """,
  name: :hook,
  schema: Pyro.Schema.Hook.schema(),
  target: Pyro.Schema.Hook,
  imports: [Pyro.Component.Template],
  args: [:name, :template]
}

# strategy = %Spark.Dsl.Entity{
#   describe: """
#   Declare/extend a CSS class strategy.
#   """,
#   name: :strategy,
#   schema: Pyro.Schema.ClassStrategy.schema(),
#   target: Pyro.Schema.ClassStrategy,
#   imports: [Pyro.Component.Template],
#   args: [:name, {:optional, :base_class}]
# }
#
# class = %Spark.Dsl.Entity{
#   describe: """
#   Declare/extend a component CSS class attribute.
#   """,
#   name: :class,
#   schema: Pyro.Schema.Class.schema(),
#   target: Pyro.Schema.Class,
#   args: [:name, {:optional, :base_class}],
#   imports: [Pyro.Component.Template],
#   entities: [
#     strategies: [strategy]
#   ]
# }

attr = %Spark.Dsl.Entity{
  describe: """
  Declare/extend a component attribute.
  """,
  name: :attr,
  schema: Pyro.Schema.Attr.schema(),
  target: Pyro.Schema.Attr,
  args: [:name, {:optional, :type}]
}

slot = %Spark.Dsl.Entity{
  describe: """
  Declare/extend a component slot.
  """,
  name: :slot,
  schema: Pyro.Schema.Slot.schema(),
  target: Pyro.Schema.Slot,
  args: [:name],
  entities: [
    attrs: [attr],
  ]
}

component = %Spark.Dsl.Entity{
  describe: """
  Declare/extend a component.
  """,
  name: :component,
  schema: Pyro.Schema.Component.schema(),
  target: Pyro.Schema.Component,
  args: [:name],
  imports: [Pyro.Component.Template],
  entities: [
    hooks: [hook],
    attrs: [attr],
    slots: [slot]
  ]
}

live_component = %Spark.Dsl.Entity{
  describe: """
  Declare/extend a live component.
  """,
  name: :live_component,
  schema: Pyro.Schema.LiveComponent.schema(),
  target: Pyro.Schema.LiveComponent,
  args: [:name],
  imports: [Pyro.Component.Template],
  entities: [
    hooks: [hook],
    attrs: [attr],
    slots: [slot],
    components: [component]
    # handle_async: [handle_async],
    # handle_event: [handle_event],
    # mount: [mount],
    # update: [update],
    # update_many: [update_many]
  ]
}

components = %Spark.Dsl.Section{
  top_level?: true,
  describe: """
  List of components to declare/extend.

  > #### Note: {: .info}
  >
  > Setting a variable will override an inherited value for the current scope, even if set to `nil`.
  """,
  name: :components,
  schema: [variables: Pyro.Schema.Variable.schema()],
  entities: [
    component,
    live_component
  ]
}

transformers = [
  Pyro.Transformer.MergeSectionVariables,
  Pyro.Transformer.MergeComponents,
  Pyro.Transformer.ApplyVariables,
  Pyro.Transformer.ApplyDefaults
]

verifiers = [Pyro.Verifier.ImplementsCssStrategies, Pyro.Verifier.ValidHooks]

sections = [components]

defmodule Pyro.Component do
  @moduledoc false

  use Spark.Dsl.Extension,
    sections: sections,
    transformers: transformers,
    verifiers: verifiers
end
