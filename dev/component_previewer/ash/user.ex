defmodule ComponentPreviewer.Ash.User do
  @moduledoc false
  use Ash.Resource,
    data_layer: Ash.DataLayer.Ets,
    extensions: [Pyro.Resource],
    notifiers: [Ash.Notifier.PubSub]

  alias ComponentPreviewer.Ash.UserRole

  require Ash.Query

  pyro do
    resource_label "User"
    default_display_mode :card_grid

    form do
      action_type [:create, :update] do
        class "max-w-md justify-self-center"

        field_group :primary do
          label "Primary Info"
          class "md:grid-cols-2"

          field :name do
            description "Your full real name"
            autofocus true
          end

          field :email
        end

        field_group :authorization do
          label "Authorization"
          class "md:grid-cols-2"

          field :roles do
            label "Roles"
            type :select
            options ComponentPreviewer.Ash.UserRole.values()
          end

          field :active do
            label "Active"
          end
        end

        field_group :friendships do
          label "Friendships"

          field :best_friend_id do
            label "Best Friend"
            type :autocomplete
            prompt "Search friends for your bestie"
            autocomplete_option_label_key :name_email
          end
        end

        field :notes do
          type :long_text
          input_class "min-h-[10rem]"
        end
      end

      action [:create, :update]
    end
  end

  pub_sub do
    prefix "user"
    module ComponentPreviewer.Endpoint

    publish_all :create, "created"
    publish_all :update, ["updated", [:id, nil]]
    publish_all :destroy, ["destroyed", [:id, nil]]
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false

    attribute :email, :string,
      sensitive?: true,
      allow_nil?: false,
      constraints: [
        max_length: 160,
        match: ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[A-Z0-9-]+(\.[A-Z0-9-]+)*$/i
      ]

    attribute :active, :boolean, allow_nil?: false, default: true

    attribute :roles, {:array, UserRole}, allow_nil?: false, default: []

    attribute :notes, :string, description: "Note anything unusual about yourself"
  end

  relationships do
    belongs_to :best_friend, __MODULE__, api: ComponentPreviewer.Ash.Api
  end

  calculations do
    calculate :name_email, :ci_string do
      calculation expr(name <> " (" <> email <> ")")
    end
  end

  actions do
    defaults [:read, :destroy]

    read :list do
      prepare build(sort: [:name])
    end

    read :autocomplete do
      argument :search, :ci_string

      prepare fn query, _ ->
        search_string = Ash.Query.get_argument(query, :search)

        query
        |> Ash.Query.filter(
          if ^search_string != "" do
            contains(name_email, ^search_string)
          else
            true
          end
        )
        |> Ash.Query.load(:name_email)
        |> Ash.Query.sort(:name_email)
        |> Ash.Query.limit(10)
      end
    end

    create :create do
      primary? true

      argument :best_friend_id, :uuid
      change manage_relationship(:best_friend_id, :best_friend, type: :append_and_remove)

      description "Just an ordinary create action."
    end

    update :update do
      primary? true

      argument :best_friend_id, :uuid
      change manage_relationship(:best_friend_id, :best_friend, type: :append_and_remove)
    end
  end

  code_interface do
    define_for ComponentPreviewer.Ash.Api

    define :autocomplete, action: :autocomplete, args: [:search]
    define :list, action: :list
    define :by_id, action: :read, get_by: [:id]
    define :create, action: :create
    define :destroy, action: :destroy
  end
end
