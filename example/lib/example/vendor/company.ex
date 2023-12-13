defmodule Example.Vendor.Company do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [Pyro.Ash.Extensions.Resource],
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub]

  pyro do
    live_view do
      page "/", :companies do
        list "/", :index, :read
        list "/another", :another, :read
        list "/one-more", :one_more, :read
        create "/create", :new, :create
        update "/edit", :edit, :update
      end
    end

    data_table do
      action_type :read do
        exclude [:id]
        column :name
      end
    end

    form do
      action_type [:create, :update] do
        field :name do
          autofocus true
        end
      end
    end
  end

  postgres do
    table "vendor_companies"
    repo Example.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :ci_string
  end

  identities do
    identity :unique_name, [:name]
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end
end
