defmodule Phlegethon.Resource do
  @field %Spark.Dsl.Entity{
    describe:
      "Declare non-default behavior for a specific form field in the `Phlegethon.Resource` extension.",
    name: :field,
    schema: Phlegethon.Resource.Form.Field.schema(),
    target: Phlegethon.Resource.Form.Field,
    args: [:name]
  }

  @field_group %Spark.Dsl.Entity{
    describe:
      "Configure the appearance of form field groups in the `Phlegethon.Resource` extension.",
    name: :field_group,
    schema: Phlegethon.Resource.Form.FieldGroup.schema(),
    target: Phlegethon.Resource.Form.FieldGroup,
    recursive_as: :fields,
    args: [:name, :label],
    entities: [
      fields: [@field]
    ]
  }

  @action %Spark.Dsl.Entity{
    describe: "",
    name: :action,
    schema: Phlegethon.Resource.Form.Action.schema(),
    target: Phlegethon.Resource.Form.Action,
    args: [:name],
    entities: [
      fields: [@field, @field_group]
    ]
  }

  @action_type %Spark.Dsl.Entity{
    describe: "",
    name: :action_type,
    schema: Phlegethon.Resource.Form.ActionType.schema(),
    target: Phlegethon.Resource.Form.ActionType,
    args: [:name],
    entities: [
      fields: [@field, @field_group]
    ]
  }

  @form %Spark.Dsl.Section{
    describe: "Configure the appearance of forms in the `Phlegethon.Resource` extension.",
    name: :form,
    entities: [
      @action,
      @action_type
    ]
  }

  @page %Spark.Dsl.Section{
    describe: "Configure this resource as a page.",
    name: :page,
    schema: [
      module: [
        required: false,
        type: :atom,
        doc:
          "The live_view module to use for the page (defaults to an automatically generated page)."
      ],
      route_path: [
        required: true,
        type: :string,
        doc: "The route path for the page"
      ]
    ]
  }

  @phlegethon %Spark.Dsl.Section{
    describe: "Configure the phlegethon dashboard for a given resource",
    name: :phlegethon,
    sections: [
      @form,
      @page
    ],
    schema: [
      resource_label: [
        type: :string,
        doc: "The proper label to use when this resource appears in the phlegethon."
      ],
      default_sort: [
        required: false,
        type: :string,
        doc: "The default sorting at page load."
      ],
      default_foreign_label: [
        required: false,
        type: :atom,
        doc: "The default field to use as a label in a foreign relationship."
      ],
      default_card_fields: [
        required: false,
        type: {:list, :atom},
        doc: "The list of fields to render in a card view."
      ],
      default_table_columns: [
        required: false,
        type: {:list, :atom},
        doc: "The list of columns to render on the table view."
      ],
      default_display_mode: [
        type: {:one_of, [:data_table, :card_grid]},
        doc: "The default display mode for a resource's page. Defaults to :data_table."
      ]
    ]
  }

  @transformers [
    Phlegethon.Resource.Transformers.MergeFormActions,
    Phlegethon.Resource.Transformers.ValidateFormActions
  ]
  @sections [@phlegethon]

  @moduledoc """
  An Ash resource extension providing declarative configuration of user interfaces via smart components.
  <!--- ash-hq-hide-start--> <!--- -->

  ## DSL Documentation

  ### Index

  #{Spark.Dsl.Extension.doc_index(@sections)}

  ### Docs

  #{Spark.Dsl.Extension.doc(@sections)}
  <!--- ash-hq-hide-stop--> <!--- -->
  """

  use Spark.Dsl.Extension, sections: @sections, transformers: @transformers
end
