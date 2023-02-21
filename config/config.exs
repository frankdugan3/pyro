import Config

config :phlegethon, gettext: Phlegethon.Gettext

config :spark, :formatter,
  remove_parens?: true,
  "Ash.Resource": [
    section_order: [
      :resource,
      :postgres,
      :authentication,
      :pub_sub,
      :attributes,
      :identities,
      :relationships,
      :aggregates,
      :calculations,
      :validations,
      :changes,
      :actions,
      :code_interface,
      :policies
    ]
  ]

import_config "#{config_env()}.exs"
