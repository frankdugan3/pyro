defmodule Example.Vendor.Company do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [Pyro.Ash.Extensions.Resource],
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub]

  pyro do
    live_view do
      page "/", :companies do
        list "/", :index, :read do
          label :inherit
          description :inherit
        end

        show "/", :show, :read
        create "/create", :new, :create
        update "/edit", :edit, :update
      end

      page "/", :show_company do
        view_as(:show_and_modal)
        show("/company", :another, :read)
        create "/create", :new, :create
        update "/edit", :edit, :update
      end

      page "/individual-company", :individuals do
        view_as :individual
        show "/show", :another, :read
        create "/create", :new, :create
        update "/edit", :edit, :update
      end
    end

    data_table do
      action :read do
        label "Du Hast Mich"
        description "Du Hasst Mich"
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
