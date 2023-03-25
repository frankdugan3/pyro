defmodule Phlegethon.Resource.Form.Field do
  @moduledoc """
  The configuration of a form field in the `Phlegethon.Resource` extension.
  """
  defstruct [:name, :type, :label, :description, :path, :class, :input_class, :autofocus]

  @schema [
    name: [
      type: :atom,
      required: true,
      doc: "The name of the field to be modified"
    ],
    type: [
      type: {:in, [:default, :long_text, :short_text, :autocomplete, :nested_form]},
      required: false,
      doc: "The type of the value in the form.",
      default: :default
    ],
    label: [
      type: :string,
      required: false,
      doc: "Override the default extracted label."
    ],
    description: [
      type: :string,
      required: false,
      doc: "Override the default extracted description."
    ],
    class: [
      type: :string,
      required: false,
      doc: "Override the field class."
    ],
    input_class: [
      type: :string,
      required: false,
      doc: "Override the input class."
    ],
    autofocus: [
      type: :boolean,
      required: false,
      default: false,
      doc: "Autofocus the field."
    ],
    path: [
      type: {:list, :atom},
      required: false,
      doc: "Override the default path (nested paths are appended)."
    ],
    autocomplete_action: [
      type: :atom,
      required: false,
      default: :autocomplete_search,
      doc: "Override the default autocomplete search action."
    ],
    autocomplete_search_argument: [
      type: :atom,
      required: false,
      default: :search,
      doc: "Override the default autocomplete search argument."
    ],
    autocomplete_option_label_field: [
      type: :atom,
      required: false,
      default: :label,
      doc: "Override the default autocomplete field used as a label."
    ]
  ]

  def schema, do: @schema
end
