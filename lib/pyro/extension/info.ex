if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Resource.Info do
    @moduledoc """
    Helpers to introspect the `Pyro.Resource` Ash extension. Intended for use in components that automatically build UI from resource configuration.
    """

    alias Phoenix.HTML.Form, as: PHXHTML
    alias Ash.Resource.Info, as: ResourceInfo
    alias Ash.Policy.Info, as: PolicyInfo
    alias Pyro.ResourceParams

    @type ash_resource_field ::
            Ash.Resource.Attribute.t()
            | Ash.Resource.Aggregate.t()
            | Ash.Resource.Calculation.t()
            | Ash.Resource.Relationships.relationship()

    @type ash_resource_field_or_name ::
            ash_resource_field()
            | binary()
            | atom()

    @type ash_action_or_name ::
            Ash.Resource.Actions.action() | binary() | atom()

    @type ash_actor :: map() | nil

    ################################################################################################
    ####    R E S O U R C E
    ################################################################################################

    @doc ~S"""
    The label of the resource as defined in the `Pyro.Resource` extension, defaulting to a humanized version of the module name.

    ## Examples

        iex> resource_label(User)
        "User"
    """
    @spec resource_label(Ash.Resource.t()) :: binary() | nil
    def resource_label(resource) do
      case Spark.Dsl.Extension.get_opt(resource, [:pyro], :resource_label, nil) do
        nil ->
          resource
          |> Module.split()
          |> List.last()
          |> humanize_module_name()

        name ->
          name
      end
    end

    defdelegate resource_description(resource), to: ResourceInfo, as: :description

    defdelegate resource?(resource), to: ResourceInfo
    defdelegate multitenancy_strategy(resource), to: ResourceInfo

    @doc ~S"""
    The default display mode of the resource as defined in the `Pyro.Resource` extension, defaulting to `:data_table`.

    ## Examples

        iex> default_display_mode(User)
        :card_grid
    """
    @spec default_display_mode(Ash.Resource.t()) :: binary()
    def default_display_mode(resource),
      do: Spark.Dsl.Extension.get_opt(resource, [:pyro], :default_display_mode, :data_table)

    ################################################################################################
    ####    A C T I O N S
    ################################################################################################

    @type primary_actions_opt :: [exclude_types: [Ash.Resource.Actions.action_type()]]

    @doc ~S"""
    Returns the list of actions of the given resource.

    Passing `exclude_types: [...]` will filter out the specified action types from the list.

    ## Examples

        iex> r = primary_actions(User)
        iex> r |> Enum.map(& &1.name)
        [:update, :create, :read]


        iex> r = primary_actions(User, exclude_types: [:create, :update])
        iex> r |> Enum.map(& &1.name)
        [:read]
    """
    @spec primary_actions(Ash.Resource.t(), [PolicyInfo.can_option() | primary_actions_opt()]) ::
            [Ash.Resource.Actions.action()]
    def primary_actions(resource, opts \\ []) do
      {exclude_types, _auth_opts} = primary_actions_opts(opts)

      resource
      |> ResourceInfo.actions()
      |> Enum.filter(fn action ->
        action.primary? == true && action.type not in exclude_types
      end)
    end

    @doc ~S"""
    The same as `primary_actions/2`, but filtered by those authorized for access for the specified action/actor.

    ## Examples

        iex> r = authorized_primary_actions(User, nil)
        iex> r |> Enum.map(& &1.name)
        []
    """
    @spec authorized_primary_actions(Ash.Resource.t(), ash_actor(), [
            PolicyInfo.can_option() | primary_actions_opt()
          ]) ::
            [Ash.Resource.Actions.action()]
    def authorized_primary_actions(resource, actor, opts \\ []) do
      {exclude_types, auth_opts} = primary_actions_opts(opts)

      resource
      |> ResourceInfo.actions()
      |> Enum.filter(fn action ->
        action.primary? == true && action.type not in exclude_types &&
          can_do?(resource, action.name, actor, auth_opts)
      end)
    end

    defp primary_actions_opts(opts) do
      exclude_types = Keyword.get(opts, :exclude_types, [])
      auth_opts = Keyword.delete(opts, :exclude_types)

      {List.wrap(exclude_types), auth_opts}
    end

    defdelegate primary_action(resource, type), to: ResourceInfo

    @doc ~S"""
    Returns the list of `:read` type actions intended for single-record reads of the given resource.

    ## Examples

        iex> r = show_actions(Record)
        iex> r |> Enum.map(& &1.name)
        [:show]
    """
    @spec show_actions(Ash.Resource.t()) :: [Ash.Resource.Actions.Read.t()]
    def show_actions(resource),
      do:
        resource
        |> ResourceInfo.actions()
        |> Enum.filter(&(&1.type == :read && &1.get? == true))

    @doc ~S"""
    The same as `show_actions/1`, but filtered by those authorized for access for the specified action/actor.

    ## Examples

        iex> r = show_actions(Record, nil)
        iex> r |> Enum.map(& &1.name)
        []
    """
    @spec show_actions(Ash.Resource.t(), ash_actor(), [PolicyInfo.can_option()]) :: [
            Ash.Resource.Actions.Read.t()
          ]
    def show_actions(resource, actor, opts \\ []),
      do:
        resource
        |> ResourceInfo.actions()
        |> Enum.filter(fn %{type: type} = action ->
          type == :read && action.get? == true &&
            can_do?(resource, action, actor, opts)
        end)

    @doc ~S"""
    Returns the list of `:read` type actions of the given resource, excluding actions that are `get?: true`.

    ## Examples

        iex> r = list_actions(Gage)
        iex> r |> Enum.map(& &1.name)
        [:calibration_alerts, :read]
    """
    @spec list_actions(Ash.Resource.t()) :: [Ash.Resource.Actions.Read.t()]
    def list_actions(resource),
      do:
        resource
        |> ResourceInfo.actions()
        |> Enum.filter(&(&1.type == :read && &1.get? == false))

    @doc ~S"""
    The same as `list_actions/1`, but filtered by those authorized for access for the specified action/actor.

    ## Examples

        iex> r = list_actions(Gage, nil)
        iex> r |> Enum.map(& &1.name)
        []
    """
    @spec list_actions(Ash.Resource.t(), ash_actor(), [PolicyInfo.can_option()]) :: [
            Ash.Resource.Actions.Read.t()
          ]
    def list_actions(resource, actor, opts \\ []),
      do:
        resource
        |> ResourceInfo.actions()
        |> Enum.filter(fn %{type: type} = action ->
          type == :read && action.get? == false &&
            can_do?(resource, action, actor, opts)
        end)

    @doc ~S"""
    Returns the list of `:create` type actions of the given resource.

    ## Examples

        iex> r = create_actions(Gage)
        iex> r |> Enum.map(& &1.name)
        [:create]
    """
    @spec create_actions(Ash.Resource.t()) :: [Ash.Resource.Actions.Create.t()]
    def create_actions(resource), do: actions_of_type(resource, :create)

    @doc ~S"""
    The same as `create_actions/1`, but filtered by those authorized for access for the specified action/actor.

    ## Examples

        iex> r = create_actions(Gage, nil)
        iex> r |> Enum.map(& &1.name)
        []
    """
    @spec create_actions(Ash.Resource.t(), ash_actor(), [PolicyInfo.can_option()]) :: [
            Ash.Resource.Actions.Create.t()
          ]
    def create_actions(resource, actor, opts \\ []),
      do: actions_of_type(resource, :create, actor, opts)

    @doc ~S"""
    Returns the list of `:read` type actions of the given resource.

    ## Examples

        iex> r = read_actions(Gage)
        iex> r |> Enum.map(& &1.name)
        [:calibration_alerts, :read]
    """
    @spec read_actions(Ash.Resource.t()) :: [Ash.Resource.Actions.Read.t()]
    def read_actions(resource), do: actions_of_type(resource, :read)

    @doc ~S"""
    The same as `read_actions/1`, but filtered by those authorized for access for the specified action/actor.

    ## Examples

        iex> r = read_actions(Gage, nil)
        iex> r |> Enum.map(& &1.name)
        []
    """
    @spec read_actions(Ash.Resource.t(), ash_actor(), [PolicyInfo.can_option()]) :: [
            Ash.Resource.Actions.Read.t()
          ]
    def read_actions(resource, actor, opts \\ []),
      do: actions_of_type(resource, :read, actor, opts)

    @doc ~S"""
    Returns the list of `:update` type actions of the given resource.

    ## Examples

        iex> r = update_actions(Gage)
        iex> r |> Enum.map(& &1.name)
        [:update]
    """
    @spec update_actions(Ash.Resource.t()) :: [Ash.Resource.Actions.Update.t()]
    def update_actions(resource), do: actions_of_type(resource, :update)

    @doc ~S"""
    The same as `update_actions/1`, but filtered by those authorized for access for the specified action/actor.

    ## Examples

        iex> r = update_actions(Gage, nil)
        iex> r |> Enum.map(& &1.name)
        []
    """
    @spec update_actions(Ash.Resource.t(), ash_actor(), [PolicyInfo.can_option()]) :: [
            Ash.Resource.Actions.Update.t()
          ]
    def update_actions(resource, actor, opts \\ []),
      do: actions_of_type(resource, :update, actor, opts)

    @doc ~S"""
    Returns the list of `:destroy` type actions of the given resource.

    ## Examples

        iex> r = destroy_actions(Gage)
        iex> r |> Enum.map(& &1.name)
        [:destroy]
    """
    @spec destroy_actions(Ash.Resource.t()) :: [Ash.Resource.Actions.Destroy.t()]
    def destroy_actions(resource), do: actions_of_type(resource, :destroy)

    @doc ~S"""
    The same as `destroy_actions/1`, but filtered by those authorized for access for the specified action/actor.

    ## Examples

        iex> r = destroy_actions(Gage, nil)
        iex> r |> Enum.map(& &1.name)
        []
    """
    @spec destroy_actions(Ash.Resource.t(), ash_actor(), [PolicyInfo.can_option()]) :: [
            Ash.Resource.Actions.Destroy.t()
          ]
    def destroy_actions(resource, actor, opts \\ []),
      do: actions_of_type(resource, :destroy, actor, opts)

    @spec default_action_for_live_action(
            Ash.Resource.t(),
            ResourceParams.live_action_type(),
            map() | nil
          ) ::
            Ash.Resource.Actions.action()
    def default_action_for_live_action(resource, live_action, actor) do
      # TODO: To make this more effective, at some point we can add a section in the UI config to specify the default, then below is a fallback.
      actions =
        case live_action do
          :show ->
            read_actions(resource, actor)

          :list ->
            list_actions(resource, actor)

          :create ->
            create_actions(resource, actor)

          :update ->
            update_actions(resource, actor)

          :destroy ->
            destroy_actions(resource, actor)

          live_action ->
            raise(
              "Live action #{live_action} is not implemented for &#{__MODULE__}.default_action_for_live_action/2!"
            )
        end
        |> List.wrap()

      case Enum.find(actions, &(&1.name == :show)) do
        nil ->
          case Enum.find(actions, &(&1.primary? == true)) do
            nil -> List.first(actions)
            action -> action
          end

        action ->
          action
      end
    end

    @doc ~S"""
    The label of the action as defined in the `Pyro.Resource` extension, defaulting to a humanized version of the action name.

    ## Examples

        iex> action_label(Gage, "calibration_alerts")
        "Calibration Alerts"

        iex> action_label(Gage, :update)
        "Update"

        iex> action_label(Gage, %{name: :read})
        "Read"
    """
    @spec action_label(Ash.Resource.t(), ash_action_or_name()) ::
            binary() | nil
    def action_label(resource, %{name: name}), do: action_label(resource, name)

    def action_label(resource, name) when is_atom(name),
      do: action_label(resource, Atom.to_string(name))

    def action_label(_resource, name) when is_binary(name),
      do:
        name
        |> String.split("_")
        |> Enum.map_join(" ", &String.capitalize/1)

    @type select_option :: [key: binary(), value: binary()]

    @doc ~S"""
    Convert a list of actions into a format compatible with `Phoenix.HTML.Form.select/4` `options`.

    ## Examples

        iex> actions_to_select_options(read_actions(Gage), Gage)
        [
          [key: "Calibration Alerts", value: "calibration_alerts"],
          [key: "Read", value: "read"]
        ]
    """
    @spec actions_to_select_options([Ash.Resource.Actions.action()], Ash.Resource.t()) ::
            [select_option()]
    def actions_to_select_options(actions, resource),
      do:
        actions
        |> Enum.map(fn %{name: name} ->
          value = Atom.to_string(name)

          key = action_label(resource, value)

          [key: key, value: value]
        end)

    def action(resource, name) when is_binary(name) do
      try do
        action(resource, String.to_existing_atom(name))
      rescue
        _ -> nil
      end
    end

    defdelegate action(resource, name), to: ResourceInfo

    @doc ~S"""
    The default sort of resource for the given action, falling back to the default provided by the `Pyro.Resource` extension.

    This is useful for extracting default sorts from preparations.

    ## Examples

        iex> default_sort(Gage, :calibration_alerts)
        "++calibration_status_expiration,calibration_status,name"

        iex> default_sort(AttendanceRecord, :read)
        "-in"

        iex> default_sort(AttendanceRecord, :current_attendance)
        "in"
    """
    @spec default_sort(Ash.Resource.t(), atom()) :: binary()
    def default_sort(resource, action) do
      case Ash.Query.for_read(resource, action).sort do
        [] ->
          with sort <- Spark.Dsl.Extension.get_opt(resource, [:pyro], :default_sort, nil),
               {:ok, _} <- Ash.Sort.parse_input(resource, sort) do
            sort
          else
            _ -> raise "Invalid default_sort for resource #{resource}!"
          end

        sort ->
          stringify_sort(sort)
      end
    end

    @spec resource_by_path(Ash.Resource.t(), [atom() | binary()]) :: Ash.Resource.t()
    def resource_by_path(resource, []), do: resource

    def resource_by_path(resource, [relationship | rest]) do
      case field(resource, relationship) do
        %Ash.Resource.Aggregate{} ->
          resource

        %Ash.Resource.Calculation{} ->
          resource

        %Ash.Resource.Attribute{} ->
          resource

        %Ash.Resource.Relationships.BelongsTo{destination: destination} ->
          resource_by_path(destination, rest)

        %Ash.Resource.Relationships.HasOne{destination: destination} ->
          resource_by_path(destination, rest)

        %Ash.Resource.Relationships.HasMany{destination: destination} ->
          resource_by_path(destination, rest)

        %Ash.Resource.Relationships.ManyToMany{destination: destination} ->
          resource_by_path(destination, rest)
      end
    end

    ################################################################################################
    ####    F I E L D S
    ################################################################################################

    @doc """
    Lists all the public fields of resource.

    ## Examples
        iex> public_fields(AttendanceType) |> Enum.map(& &1.name)
        [
          :label,
          :order,
          :shortcut,
          :notes,
          :inserted_at,
          :updated_at,
          :id,
          :records_count,
          :records
        ]
    """
    @spec public_fields(Ash.Resource.t()) :: [ash_resource_field()]
    def public_fields(resource),
      do:
        resource
        |> ResourceInfo.public_attributes()
        |> Enum.concat(ResourceInfo.public_aggregates(resource))
        |> Enum.concat(ResourceInfo.public_calculations(resource))
        |> Enum.concat(ResourceInfo.public_relationships(resource))

    @doc """
    The same as `public_fields/1`, but filtered by those authorized for access for the specified action/actor.

    ## Examples
        iex> public_fields(AttendanceType, :read, nil) |> Enum.map(& &1.name)
        []
    """
    @spec public_fields(
            Ash.Resource.t(),
            ash_action_or_name(),
            ash_actor()
          ) :: [ash_resource_field()]
    def public_fields(resource, action, actor),
      do:
        resource
        |> public_fields()
        |> Enum.filter(&field_authorized?(&1, resource, action, actor))

    @doc """
    Returns the field defined in the `Pyro.Resource` extension as a default label, falling back to the first single-key identity of the resource, further falling back to the primary key if it's single-keyed.

    ## Examples

        iex> default_foreign_label(AttendanceType)
        :label

        iex> default_foreign_label(Gage)
        :name
    """
    @spec default_foreign_label(Ash.Resource.t()) :: atom()
    def default_foreign_label(resource),
      do:
        resource
        |> Spark.Dsl.Extension.get_opt([:pyro], :default_foreign_label, nil) ||
          default_single_field_identity_key(resource)

    @doc """
    Returns the given field's description.

    ## Examples

        iex> field_description(AttendanceType, :clockable)
        "Clockable types are available for employees to punch in/out at kiosks and workstations."
    """
    @spec field_description(
            Ash.Resource.t(),
            ash_resource_field_or_name()
          ) :: atom()
    def field_description(_resource, %{__struct__: struct_name, description: description})
        when struct_name in [
               Ash.Resource.Relationships.HasMany,
               Ash.Resource.Relationships.HasOne,
               Ash.Resource.Relationships.BelongsTo,
               Ash.Resource.Relationships.ManyToMany,
               Ash.Resource.Aggregate,
               Ash.Resource.Calculation,
               Ash.Resource.Attribute
             ],
        do: description

    def field_description(resource, name),
      do: field_description(resource, ResourceInfo.field(resource, name))

    @doc """
    WIP label for resource fields. In the future it will pull from a resource field property. This will allow different labels based on context.
    """
    def field_label(resource, _action, field) do
      resource
      |> ResourceInfo.field(field)
      |> humanize_field()
    end

    @doc """
    Returns the form fields defined in the `Pyro.Resource` extension for the given action.

    ## Examples

        iex> form_for(AttendanceRecord, :create) |> Enum.map(& &1.name)
        [:notes, :employee_id, :type_id]
    """
    @spec form_for(Ash.Resource.t(), atom()) :: [
            Pyro.Resource.Form.Field.t() | Pyro.Resource.Form.FieldGroup.t()
          ]
    def form_for(resource, action_name) do
      resource
      |> Spark.Dsl.Extension.get_entities([:pyro, :form])
      |> Enum.find(fn action ->
        action.name == action_name
      end)
    end

    #     @doc """
    #   Returns the specified form field defined in the `Pyro.Resource` extension for the given action.

    #   ## Examples

    #       iex> form_field(AttendanceRecord, :create, :label)
    #       %Pyro.Resource.Form.Field{name: :label}
    #   """
    #   @spec form_field(Ash.Resource.t(), atom(), atom(), [atom()]) :: [
    #     Pyro.Resource.Form.Field.t() | Pyro.Resource.Form.FieldGroup.t()
    #   ]
    # def form_field(resource, action_name, field_name, path \\ []) do
    # resource
    # |> Spark.Dsl.Extension.get_entities([:pyro, :form])
    # |> Enum.find(fn action ->
    # action.name == action_name
    # end)
    # end

    # defp get_field(fields, name, path), do:

    @doc ~S"""
    Check if a given field is authorized to be viewed by the actor.

    ## Examples

        iex> field_authorized?("name", Gage, "read", nil)
        false

        iex> field_authorized?(:owner, Gage, :read, %{roles: [:Employee], active: true})
        true

    > #### Note: {: .warning}
    >
    > Currently, fields that _may_ be authorized depending on actor's attributes are authorized. We may eventually want to more intelligently deal with this, because currently a `nil` actor will return true. This particular case will handled when [#372](https://github.com/ash-project/ash/issues/372) is closed. This is mostly UI concern, because the query will still be safely validated and would fail, but we don't want to clutter the UI with fields that can't actually be loaded.

        iex> field_authorized?(:owner, Gage, :read, nil)
        false

    > #### Note: {: .warning}
    >
    > We are not currently handling field-level authz for create/update types. This can probably be done by leveraging `Ash.Generator` to seed changeset data for the given field. This should allow determine e.g. if a relationship is editable by the actor, allow forms to hide relationships that an actor can't edit.
    """
    @spec field_authorized?(
            ash_resource_field_or_name(),
            Ash.Resource.t(),
            ash_action_or_name(),
            ash_actor(),
            keyword()
          ) :: boolean()
    def field_authorized?(field, resource, action, actor, opts \\ [])

    def field_authorized?(field, resource, action, actor, opts)
        when is_atom(action) or is_binary(action),
        do: field_authorized?(field, resource, action(resource, action), actor, opts)

    def field_authorized?(field, resource, action, actor, opts)
        when is_atom(field) or is_binary(field),
        do: field_authorized?(field(resource, field), resource, action, actor, opts)

    def field_authorized?(_field, _resource, _action, _actor, _opts) do
      # api = Keyword.get(opts, :api)
      # maybe_is = Keyword.get(opts, :maybe_is, :maybe)

      # TODO: Actually deal with this
      true
      # case action.type do
      #   :update ->
      #     query =
      #       struct(resource)
      #       |> Ash.Changeset.new(%{})
      #       |> Ash.Changeset.for_update(action.name)

      #     run_check(actor, query, api: api, maybe_is: maybe_is)

      #   :create ->
      #     query =
      #       resource
      #       |> Ash.Changeset.new()
      #       |> Ash.Changeset.for_create(action.name)

      #     run_check(actor, query, api: api, maybe_is: maybe_is)

      #   :read ->
      #     query =
      #       Ash.Query.for_read(resource, action.name)
      #       |> select_or_load_field(field)

      #     run_check(actor, query, api: api, maybe_is: maybe_is)

      #   :destroy ->
      #     query =
      #       struct(resource)
      #       |> Ash.Changeset.new()
      #       |> Ash.Changeset.for_destroy(action.name)

      #     run_check(actor, query, api: api, maybe_is: maybe_is)

      #   action_type ->
      #     raise ArgumentError, message: "Invalid action type \"#{action_type}\""
      # end
    end

    defdelegate field(resource, field), to: ResourceInfo

    def field(resource, field, action, actor, opts \\ []) do
      case field(resource, field) do
        nil -> nil
        field -> if field_authorized?(field, resource, action, actor, opts), do: field, else: nil
      end
    end

    defdelegate public_attributes(resource), to: ResourceInfo
    defdelegate attribute(resource, name), to: ResourceInfo
    defdelegate public_aggregates(resource), to: ResourceInfo
    defdelegate aggregate(resource, name), to: ResourceInfo
    defdelegate public_calculations(resource), to: ResourceInfo
    defdelegate calculation(resource, name), to: ResourceInfo

    @doc ~S"""
    Check if a field is sortable.

    ## Examples

        iex> sortable_field?(User, field(User, :email))
        true

        iex> sortable_field?(User, :name)
        true
    """
    @spec sortable_field?(
            Ash.Resource.t(),
            ash_resource_field_or_name()
          ) :: boolean()
    def sortable_field?(resource, %{name: name}), do: sortable_field?(resource, name)
    defdelegate sortable_field?(resource, field), to: ResourceInfo, as: :sortable?

    @doc ~S"""
    Filter the list of fields to those which can be loaded (as opposed to those which can be selected). Basically just filters out attributes from a list of fields.

    ## Examples

    Explicitly configured

        iex> default_table_columns(User) |> loadable_fields(User)
        [:best_friend]
    """
    @spec loadable_fields([ash_resource_field()], Ash.Resource.t()) :: [atom()]
    def loadable_fields(fields, resource),
      do:
        fields
        |> Enum.filter(&(!ResourceInfo.attribute(resource, &1.name)))
        |> Enum.map(& &1.name)

    ################################################################################################
    ####    P A G E
    ################################################################################################

    @doc ~S"""
    The custom page module of the action as defined in the `Pyro.Resource` extension, if the resource is configured as a custom page.

    ## Examples

        iex> page_module(User)
        nil
    """
    @spec page_module(Ash.Resource.t()) :: module() | nil
    def page_module(resource),
      do:
        Spark.Dsl.Extension.get_opt(
          resource,
          [:pyro, :page],
          :module,
          nil
        )

    @doc ~S"""
    The page routing path of the resource as defined in the `Pyro.Resource` extension, if the resource is configured as a page.

    ## Examples

        iex> page_route_path(AttendanceType)
        "attendance-types"
    """
    @spec page_route_path(Ash.Resource.t()) :: binary() | nil
    def page_route_path(resource),
      do:
        Spark.Dsl.Extension.get_opt(
          resource,
          [:pyro, :page],
          :route_path,
          nil
        )

    @doc ~S"""
    Return a boolean indicating if resource is a page as configured in the `Pyro.Resource` extension.

    ## Examples

        iex> is_page?(AttendanceType)
        true
    """
    @spec is_page?(Ash.Resource.t()) :: boolean()
    def is_page?(resource) do
      !!Spark.Dsl.Extension.get_opt(
        resource,
        [:pyro, :page],
        :route_path,
        false
      )
    end

    # @doc ~S"""
    # Return a of resources configured as a page in the `Pyro.Resource` extension.

    # ## Examples

    #     iex> pages(api) |> length() > 1
    #     true

    # """
    # @spec pages(Ash.Api.t()) :: [Ash.Resource.t()]
    # def pages(api) do
    #   Ash.Api.Info.resources(api) |> Enum.filter(&is_page?/1)
    # end

    @doc ~S"""
    Return the page limit options for the given resource/action if pagination is configured.

    ## Examples

        iex> page_limit_options(AttendanceType, :read)
        [10, 25, 50, 100, 250]
    """
    @spec page_limit_options(Ash.Resource.t(), atom() | binary()) :: [pos_integer()]
    def page_limit_options(resource, action_name) do
      %{pagination: %{max_page_size: max_page_size}} = ResourceInfo.action(resource, action_name)

      [10, 25, 50, 100, 250, 500]
      |> Enum.filter(fn value -> value <= max_page_size end)
    end

    @doc ~S"""
    Return the default page for the given resource/action.

    ## Examples

        iex> default_page_limit(AttendanceType, :read)
        25
    """
    @spec default_page_limit(Ash.Resource.t(), atom() | binary()) :: pos_integer()
    def default_page_limit(resource, action_name) do
      # TODO: Add ability to define in UI so it can be a default without forcing a default for every call.
      case ResourceInfo.action(resource, action_name) do
        %{pagination: %{default_limit: default_limit}} when is_integer(default_limit) ->
          default_limit

        _ ->
          25
      end
    end

    ################################################################################################
    ####    T A B L E
    ################################################################################################

    @doc ~S"""
    The default table columns to display as defined in the `Pyro.Resource` extension, with fallback to all public fields.

    ## Examples

    Explicitly configured

        iex> r = default_table_columns(User)
        iex> r |> Enum.map(& &1.name)
        [:name, :email, :notes]
    """
    @spec default_table_columns(Ash.Resource.t()) :: [ash_resource_field()]
    def default_table_columns(resource) do
      case Spark.Dsl.Extension.get_opt(
             resource,
             [:pyro],
             :default_table_columns,
             :undefined
           ) do
        :undefined ->
          resource
          |> public_fields()

        columns ->
          columns
          |> Enum.map(fn name ->
            case ResourceInfo.field(resource, name) do
              nil -> raise "Column #{name} is not a public field on #{resource}!"
              column -> column
            end
          end)
      end
    end

    @doc ~S"""
    Same as `default_table_columns/1`, but filtered by those authorized for access for the specified action/actor.

    ## Examples
        iex> r = default_table_columns(Gage, :calibration_alerts, nil)
        iex> r |> Enum.map(& &1.name)
        []
    """
    @spec default_table_columns(Ash.Resource.t(), Ash.Resource.Action.t(), ash_actor()) :: [
            ash_resource_field()
          ]
    def default_table_columns(resource, action, actor),
      do:
        resource
        |> default_table_columns()
        |> Enum.filter(&field_authorized?(&1, resource, action, actor))

    ################################################################################################
    ####    C A R D
    ################################################################################################

    @doc ~S"""
    The default card fields to display as defined in the `Pyro.Resource` extension, with fallback to all public fields.

    ## Examples

    Explicitly configured

        iex> r = default_card_fields(AttendanceRecord)
        iex> r |> Enum.map(& &1.name)
        [
          :inserted_at,
          :updated_at,
          :in,
          :out,
          :duration_hours,
          :type_label,
          :employee_code,
          :employee_name_formal,
          :notes
        ]
    """
    @spec default_card_fields(Ash.Resource.t()) :: [ash_resource_field()]
    def default_card_fields(resource) do
      case Spark.Dsl.Extension.get_opt(
             resource,
             [:pyro],
             :default_card_fields,
             :undefined
           ) do
        :undefined ->
          resource
          |> public_fields()

        fields ->
          fields
          |> Enum.map(fn name ->
            case ResourceInfo.field(resource, name) do
              nil -> raise "Field #{name} is not a public field on #{resource}!"
              field -> field
            end
          end)
      end
    end

    @doc ~S"""
    Same as `default_card_fields/1`, but filtered by those authorized for access for the specified action/actor.

    ## Examples
        iex> r = default_card_fields(Gage, :calibration_alerts, nil)
        iex> r |> Enum.map(& &1.name)
        []
    """
    @spec default_card_fields(Ash.Resource.t(), Ash.Resource.Action.t(), ash_actor()) :: [
            ash_resource_field()
          ]
    def default_card_fields(resource, action, actor),
      do:
        resource
        |> default_card_fields()
        |> Enum.filter(&field_authorized?(&1.name, resource, action, actor))

    ################################################################################################
    ####    F O R M S
    ################################################################################################

    @doc ~S"""
    This is only used for the primary user input. This provides consistency between the input component and other parts of the UI that may want ot provide a link to that user input e.g. to click an error and focus the related input.

    ## Examples
        iex> form = AshPhoenix.Form.for_create(AttendanceType, :create)
        iex> input_id(form, :label)
        "form_label"
    """
    @spec input_id(AshPhoenix.Form.t(), atom()) :: binary()
    def input_id(form, field) do
      # resource = form.source.resource
      # form_field_type = form_field(resource, field).type

      # TODO: This needs to be revisited!

      # append =
      #   case form_field_type do
      #     :autocomplete -> "_autocomplete_input"
      #     _ -> ""
      #   end

      # <> append
      PHXHTML.input_id(form, field)
    end

    ################################################################################################
    ####    R E L A T I O N S H I P S
    ################################################################################################

    defdelegate reverse_relationship(resource, path), to: ResourceInfo
    defdelegate relationship(resource, path), to: ResourceInfo
    defdelegate related(resource, path), to: ResourceInfo

    ################################################################################################
    ####    I D E N T I T I E S
    ################################################################################################

    @doc ~S"""
    List the single-keyed identities of the given resource.

    ## Examples

        iex> single_field_identities(User)
        [
          %Ash.Resource.Identity{
            description: nil,
            eager_check_with: nil,
            keys: [:email],
            name: :name,
            pre_check_with: nil
          }
        ]
    """
    @spec single_field_identities(Ash.Resource.t()) :: [Ash.Resource.Identity.t()]
    def single_field_identities(resource),
      do:
        resource
        |> ResourceInfo.identities()
        |> Enum.filter(&(length(&1.keys) == 1))

    @doc ~S"""
    The first single-keyed identity, or the primary ID of the given resource.

    ## Examples

    iex> default_single_field_identity_key(User)
    :email
    """
    @spec default_single_field_identity_key(Ash.Resource.t()) :: :atom
    def default_single_field_identity_key(resource) do
      case single_field_identities(resource) do
        [] ->
          [key] = ResourceInfo.primary_key(resource)
          key

        [%{keys: [key]} | _rest] ->
          key
      end
    end

    ################################################################################################
    ####    P O L I C I E S
    ################################################################################################

    defdelegate policies(resource), to: PolicyInfo
    defdelegate can_do?(resource, action_or_query, actor, opts), to: PolicyInfo, as: :can?
    # @doc ~S"""
    # The description of the resource as defined in the resource DSL.

    # ## Examples

    #     iex> resource_description(Gage)
    #     "An inventoried gage, subject to calibration."
    # """
    # @spec can_do?(
    #         Ash.Resource.t(),
    #         Ash.Resource.Action.t() | atom(),
    #         ash_actor(),
    #         [PolicyInfo.can_option()]
    #       ) :: boolean()
    # def can_do?(resource, action_or_query, actor, opts \\ []) do
    #   opts = [api: Keyword.get(opts, :api), maybe_is: Keyword.get(opts, :maybe_is, true)]

    #   prepare_can_do?(resource, action_or_query, actor, opts)
    # end

    # defp prepare_can_do?(resource, %Ash.Query{} = action_or_query, actor, opts),
    #   do: PolicyInfo.can(resource, action_or_query, actor, opts)

    # defp prepare_can_do?(resource, action_name, actor, opts) when is_atom(action_name),
    #   do: prepare_can_do?(resource, action(resource, action_name), actor, opts)

    # defp prepare_can_do?(
    #        _resource,
    #        %{type: :read, arguments: arguments, name: _name},
    #        _actor,
    #        _opts
    #      )
    #      when is_list(arguments) and arguments != [] do
    #   # args =
    #   #   arguments
    #   #   |> Enum.filter(&(&1.allow_nil? == false))
    #   #   |> Enum.map(fn argument ->
    #   #     case argument do
    #   #       %{name: name, type: Ash.Type.UtcDatetimeUsec} -> {name, DateTime.now!("Etc/UTC")}
    #   #       %{name: name, type: {:array, _}} -> {name, []}
    #   #       %{name: name} -> {name, "a"}
    #   #     end
    #   #   end)

    #   # query = Ash.Query.for_read(resource, name, args)

    #   # PolicyInfo.can(resource, query, actor, opts)
    #   # NOTE: Temporarily disabled for future enablement.
    #   false
    # end

    # defp prepare_can_do?(resource, action_or_query, actor, opts),
    #   do: PolicyInfo.can(resource, action_or_query, actor, opts)

    ################################################################################################
    ####    I N T E R N A L    T O O L I N G
    ################################################################################################

    defp stringify_sort(sort), do: sort |> Enum.map(&stringify_sort_field/1) |> Enum.join(",")

    defp stringify_sort_field({%Ash.Query.Aggregate{name: name}, dir}),
      do: stringify_sort_dir(dir) <> Atom.to_string(name)

    defp stringify_sort_field({%Ash.Query.Calculation{name: name}, dir}),
      do: stringify_sort_dir(dir) <> Atom.to_string(name)

    defp stringify_sort_field({name, dir}) when is_atom(name),
      do: stringify_sort_dir(dir) <> Atom.to_string(name)

    defp stringify_sort_dir(:asc), do: ""
    defp stringify_sort_dir(:asc_nils_first), do: "++"
    defp stringify_sort_dir(:desc), do: "-"
    defp stringify_sort_dir(:desc_nils_last), do: "--"

    defp actions_of_type(resource, type),
      do:
        resource
        |> ResourceInfo.actions()
        |> Enum.filter(&(&1.type == type))

    defp actions_of_type(resource, type, actor, opts),
      do:
        resource
        |> ResourceInfo.actions()
        |> Enum.filter(fn %{type: t} = action ->
          t == type && can_do?(resource, action, actor, opts)
        end)

    # defp select_or_load_field(query, %{__struct__: struct_name, name: field_name}) do
    #   case struct_name do
    #     sn
    #     when sn in [
    #            Ash.Resource.Relationships.HasMany,
    #            Ash.Resource.Relationships.HasOne,
    #            Ash.Resource.Relationships.BelongsTo,
    #            Ash.Resource.Relationships.ManyToMany,
    #            Ash.Resource.Aggregate,
    #            Ash.Resource.Calculation
    #          ] ->
    #       query
    #       |> Ash.Query.select([], replace?: true)
    #       |> Ash.Query.load([field_name])

    #     _ ->
    #       query |> Ash.Query.select([field_name], replace?: true)
    #   end
    # end

    defp humanize_field(%{name: name}), do: humanize_field(name)
    defp humanize_field(name) when is_atom(name), do: name |> Atom.to_string() |> humanize_field()

    defp humanize_field(name) when is_binary(name),
      do:
        name
        |> String.split("_")
        |> Enum.map_join(" ", &String.capitalize/1)

    defp humanize_module_name(atom) when is_atom(atom) do
      humanize_module_name(Atom.to_string(atom))
    end

    defp humanize_module_name(<<h, t::binary>>) do
      <<h>> <> do_humanize_module_name(t, h)
    end

    defp humanize_module_name("") do
      ""
    end

    defp do_humanize_module_name(<<h, t, rest::binary>>, _)
         when h >= ?A and h <= ?Z and not (t >= ?A and t <= ?Z) and not (t >= ?0 and t <= ?9) and
                t != ?. and t != " " do
      <<" ", h, t>> <> do_humanize_module_name(rest, t)
    end

    defp do_humanize_module_name(<<h, t::binary>>, prev)
         when h >= ?A and h <= ?Z and not (prev >= ?A and prev <= ?Z) and prev != " " do
      <<" ", h>> <> do_humanize_module_name(t, h)
    end

    defp do_humanize_module_name(<<?., t::binary>>, _) do
      <<?/>> <> humanize_module_name(t)
    end

    defp do_humanize_module_name(<<h, t::binary>>, _) do
      <<h>> <> do_humanize_module_name(t, h)
    end

    defp do_humanize_module_name(<<>>, _) do
      <<>>
    end
  end
end
