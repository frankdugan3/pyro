if Code.ensure_loaded?(Ash) do
  form_field = %Spark.Dsl.Entity{
    describe: "Declare non-default behavior for a specific form field in the `Pyro.Ash.Extensions.Resource` extension.",
    name: :field,
    schema: Pyro.Ash.Extensions.Resource.Form.Field.schema(),
    target: Pyro.Ash.Extensions.Resource.Form.Field,
    args: [:name]
  }

  form_field_group = %Spark.Dsl.Entity{
    describe: "Configure the appearance of form field groups in the `Pyro.Ash.Extensions.Resource` extension.",
    name: :field_group,
    schema: Pyro.Ash.Extensions.Resource.Form.FieldGroup.schema(),
    target: Pyro.Ash.Extensions.Resource.Form.FieldGroup,
    recursive_as: :fields,
    args: [:name],
    entities: [
      fields: [form_field]
    ]
  }

  form_action = %Spark.Dsl.Entity{
    describe: "Configure the appearance forms forms for specific action(s).",
    name: :action,
    schema: Pyro.Ash.Extensions.Resource.Form.Action.schema(),
    target: Pyro.Ash.Extensions.Resource.Form.Action,
    args: [:name],
    entities: [
      fields: [form_field, form_field_group]
    ]
  }

  form_action_type = %Spark.Dsl.Entity{
    describe:
      "Configure default form appearance for actions of type(s). Will be ignored by actions configured explicitly.",
    name: :action_type,
    schema: Pyro.Ash.Extensions.Resource.Form.ActionType.schema(),
    target: Pyro.Ash.Extensions.Resource.Form.ActionType,
    args: [:name],
    entities: [
      fields: [form_field, form_field_group]
    ]
  }

  form = %Spark.Dsl.Section{
    describe: "Configure the appearance of forms in the `Pyro.Ash.Extensions.Resource` extension.",
    name: :form,
    schema: [
      exclude: [
        required: false,
        type: {:list, :atom},
        doc: "The actions to exclude from forms.",
        default: []
      ]
    ],
    entities: [
      form_action,
      form_action_type
    ]
  }

  data_table_column = %Spark.Dsl.Entity{
    describe:
      "Declare non-default behavior for a specific data table column in the `Pyro.Ash.Extensions.Resource` extension.",
    name: :column,
    schema: Pyro.Ash.Extensions.Resource.DataTable.Column.schema(),
    target: Pyro.Ash.Extensions.Resource.DataTable.Column,
    args: [:name]
  }

  data_table_action = %Spark.Dsl.Entity{
    describe: "Configure the appearance of the data table for specific action(s).",
    name: :action,
    schema: Pyro.Ash.Extensions.Resource.DataTable.Action.schema(),
    target: Pyro.Ash.Extensions.Resource.DataTable.Action,
    args: [:name],
    entities: [
      columns: [data_table_column]
    ]
  }

  data_table_action_type = %Spark.Dsl.Entity{
    describe:
      "Configure the default data table appearance for actions of type(s). Will be ignored by actions configured explicitly.",
    name: :action_type,
    schema: Pyro.Ash.Extensions.Resource.DataTable.ActionType.schema(),
    target: Pyro.Ash.Extensions.Resource.DataTable.ActionType,
    args: [:name],
    entities: [
      columns: [data_table_column]
    ]
  }

  data_table = %Spark.Dsl.Section{
    describe: "Configure the appearance of data tables in the `Pyro.Ash.Extensions.Resource` extension.",
    name: :data_table,
    schema: [
      exclude: [
        required: false,
        type: {:list, :atom},
        doc: "The actions to exclude from data tables.",
        default: []
      ]
    ],
    entities: [
      data_table_action,
      data_table_action_type
    ]
  }

  live_view_list = %Spark.Dsl.Entity{
    describe: "Configure a list action for this resource.",
    name: :list,
    schema: Pyro.Ash.Extensions.Resource.LiveView.Page.List.schema(),
    target: Pyro.Ash.Extensions.Resource.LiveView.Page.List,
    args: [:path, :live_action, :action]
  }

  live_view_show = %Spark.Dsl.Entity{
    describe: "Configure a show action for this resource.",
    name: :show,
    schema: Pyro.Ash.Extensions.Resource.LiveView.Page.Show.schema(),
    target: Pyro.Ash.Extensions.Resource.LiveView.Page.Show,
    args: [:path, :live_action, :action]
  }

  live_view_create = %Spark.Dsl.Entity{
    describe: "Configure a create action for this resource.",
    name: :create,
    schema: Pyro.Ash.Extensions.Resource.LiveView.Page.Create.schema(),
    target: Pyro.Ash.Extensions.Resource.LiveView.Page.Create,
    args: [:path, :live_action, :action]
  }

  live_view_update = %Spark.Dsl.Entity{
    describe: "Configure a update action for this resource.",
    name: :update,
    schema: Pyro.Ash.Extensions.Resource.LiveView.Page.Update.schema(),
    target: Pyro.Ash.Extensions.Resource.LiveView.Page.Update,
    args: [:path, :live_action, :action]
  }

  live_view_page = %Spark.Dsl.Entity{
    describe: "Configure a page for this resource.",
    name: :page,
    schema: Pyro.Ash.Extensions.Resource.LiveView.Page.schema(),
    target: Pyro.Ash.Extensions.Resource.LiveView.Page,
    args: [:path, :name, :api],
    identifier: :name,
    entities: [
      live_actions: [live_view_list, live_view_show, live_view_create, live_view_update]
    ]
  }

  live_view = %Spark.Dsl.Section{
    describe: "Configure LiveViews in the `Pyro.Ash.Extensions.Resource` extension.",
    name: :live_view,
    schema: [],
    entities: [live_view_page]
  }

  pyro = %Spark.Dsl.Section{
    describe: "Configure the pyro dashboard for a given resource",
    name: :pyro,
    sections: [
      data_table,
      form,
      live_view
    ],
    schema: [
      resource_label: [
        type: :string,
        doc: "The proper label to use when this resource appears in the pyro."
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

  transformers = [
    Pyro.Ash.Extensions.Resource.Transformers.MergeDataTableActions,
    Pyro.Ash.Extensions.Resource.Transformers.MergeFormActions,
    Pyro.Ash.Extensions.Resource.Transformers.MergePages
  ]

  verifiers = [
    Pyro.Ash.Extensions.Resource.Verifiers.DataTableActions,
    Pyro.Ash.Extensions.Resource.Verifiers.FormActions
  ]

  sections = [pyro]

  defmodule Pyro.Ash.Extensions.Resource do
    @moduledoc """
    An Ash resource extension providing declarative configuration of user interfaces via smart components.
    <!--- ash-hq-hide-start--> <!--- -->

    ## DSL Documentation

    ### Index

    #{Spark.Dsl.Extension.doc_index(sections)}

    ### Docs

    #{Spark.Dsl.Extension.doc(sections)}
    <!--- ash-hq-hide-stop--> <!--- -->
    """
    use Spark.Dsl.Extension, sections: sections, transformers: transformers, verifiers: verifiers
  end
end
