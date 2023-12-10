defmodule Example.Repo do
  use AshPostgres.Repo,
    otp_app: :example

  def installed_extensions() do
    [
      "pgcrypto",
      "uuid-ossp",
      "pg_trgm",
      "citext",
      "btree_gist",
      "pg_stat_statements",
      "fuzzystrmatch",
      "pg_stat_statements",
      "ash-functions"
    ]
  end
end
