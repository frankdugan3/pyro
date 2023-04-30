if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Resource do
    @field %Spark.Dsl.Entity{
      describe:
        "Declare non-default behavior for a specific form field in the `Pyro.Resource` extension.",
      name: :field,
      schema: Pyro.Resource.Form.Field.schema(),
      target: Pyro.Resource.Form.Field,
      args: [:name]
    }

    @field_group %Spark.Dsl.Entity{
      describe:
        "Configure the appearance of form field groups in the `Pyro.Resource` extension.",
      name: :field_group,
      schema: Pyro.Resource.Form.FieldGroup.schema(),
      target: Pyro.Resource.Form.FieldGroup,
      recursive_as: :fields,
      args: [:name, :label],
      entities: [
        fields: [@field]
      ]
    }

    @action %Spark.Dsl.Entity{
      describe: "",
      name: :action,
      schema: Pyro.Resource.Form.Action.schema(),
      target: Pyro.Resource.Form.Action,
      args: [:name],
      entities: [
        fields: [@field, @field_group]
      ]
    }

    @action_type %Spark.Dsl.Entity{
      describe: "",
      name: :action_type,
      schema: Pyro.Resource.Form.ActionType.schema(),
      target: Pyro.Resource.Form.ActionType,
      args: [:name],
      entities: [
        fields: [@field, @field_group]
      ]
    }

    @form %Spark.Dsl.Section{
      describe: "Configure the appearance of forms in the `Pyro.Resource` extension.",
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

    @pyro %Spark.Dsl.Section{
      describe: "Configure the pyro dashboard for a given resource",
      name: :pyro,
      sections: [
        @form,
        @page
      ],
      schema: [
        resource_label: [
          type: :string,
          doc: "The proper label to use when this resource appears in the pyro."
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
      Pyro.Resource.Transformers.MergeFormActions,
      Pyro.Resource.Transformers.ValidateFormActions
    ]
    @sections [@pyro]

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
end
