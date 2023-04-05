if Code.ensure_loaded?(Ash) do
  defmodule Phlegethon.Resource.Form.FieldGroup do
    @moduledoc """
    A group of form fields in the `Phlegethon.Resource` extension.
    """
    defstruct [:name, :label, :class, :path, :fields]

    @schema [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the field to be modified"
      ],
      label: [
        type: :string,
        required: false,
        doc: "The label for this group."
      ],
      class: [
        type: :string,
        required: false,
        doc: "Override the default class.",
        default: "grid col-span-full"
      ],
      path: [
        type: {:list, :atom},
        required: false,
        doc: "Override the default path (nested paths are appended)."
      ]
    ]

    def schema, do: @schema
  end
end
