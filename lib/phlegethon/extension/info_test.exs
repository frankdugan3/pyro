defmodule Phlegethon.Resource.InfoTest do
  @moduledoc false
  use ExUnit.Case, async: true

  require Ash.Query

  doctest Phlegethon.Resource.Info, import: true

  defmodule User do
    @moduledoc false
    use Ash.Resource,
      data_layer: Ash.DataLayer.Ets,
      extensions: [Phlegethon.Resource]

    phlegethon do
      resource_label "User"
      default_display_mode :card_grid
    end

    ets do
      private? true
    end

    actions do
      read :read do
        primary? true
      end

      read :by_id do
        argument :id, :uuid, allow_nil?: false

        filter(expr(id == ^arg(:id)))
      end

      create :create
      update :update
    end

    attributes do
      uuid_primary_key :id
      attribute :name, :string
      attribute :email, :string, sensitive?: true
    end

    relationships do
      belongs_to :best_friend, __MODULE__
    end
  end

  defmodule Registry do
    @moduledoc false
    use Ash.Registry

    entries do
      entry User
    end
  end

  defmodule Api do
    use Ash.Api

    resources do
      registry Registry
    end
  end
end
