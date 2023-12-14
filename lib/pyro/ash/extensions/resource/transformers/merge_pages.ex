if Code.ensure_loaded?(Ash) do
  defmodule Pyro.Ash.Extensions.Resource.Transformers.MergePages do
    @moduledoc false

    use Pyro.Ash.Extensions.Resource.Transformers
    alias Pyro.Ash.Extensions.Resource.LiveView.Page

    @dependant_transformers Ash.Resource.Dsl.transformers() ++
                              [
                                Pyro.Ash.Extensions.Resource.Transformers.MergeFormActions,
                                Pyro.Ash.Extensions.Resource.Transformers.MergeDataTableActions
                                # Pyro.Ash.Extensions.Resource.Transformers.MergeCardGridActions
                              ]

    @impl true
    def after?(module) when module in @dependant_transformers, do: true
    @impl true
    def after?(_), do: false

    @impl true
    def transform(dsl) do
      errors = []

      case Transformer.get_entities(dsl, [:pyro, :live_view]) do
        [] ->
          {:ok, dsl}

        page_entities ->
          {dsl, errors} = Enum.reduce(page_entities, {dsl, errors}, &merge_page/2)

          handle_errors(errors, "live view pages", dsl)
      end
    end

    defp merge_page(
           %Page{view_as: :list_and_modal, live_actions: live_actions} = page,
           {dsl, errors}
         ) do
      live_action_types =
        live_actions
        |> Enum.map(&expand_live_action_defaults(&1, dsl))
        |> partition_live_actions()

      live_actions =
        Enum.reduce(live_action_types.list, [], fn list, acc ->
          child_actions =
            Enum.concat([
              live_action_types.show,
              live_action_types.create,
              live_action_types.update
            ])

          acc =
            Enum.reduce(child_actions, acc, fn action, acc ->
              path =
                build_path([page.path, list.path, identity_to_path(action.identity), action.path])

              live_action = String.to_atom("#{list.live_action}_#{action.live_action}")
              [%{action | path: path, live_action: live_action} | acc]
            end)

          [%{list | path: build_path([page.path, list.path])} | acc]
        end)

      page = %{page | live_actions: live_actions}
      dsl = Transformer.replace_entity(dsl, [:pyro, :live_view], page)

      {dsl, errors}
    end

    defp merge_page(
           %Page{view_as: :show_and_modal, live_actions: live_actions} = page,
           {dsl, errors}
         ) do
      live_action_types =
        live_actions
        |> Enum.map(&expand_live_action_defaults(&1, dsl))
        |> partition_live_actions()

      list_actions =
        Enum.map(live_action_types.list, fn list ->
          %{list | path: build_path([page.path, list.path])}
        end)

      live_actions =
        Enum.reduce(live_action_types.show, list_actions, fn show, acc ->
          show_identity = identity_to_path(show.identity)

          acc =
            Enum.reduce(live_action_types.update, acc, fn update, acc ->
              path =
                build_path([
                  page.path,
                  show_identity,
                  show.path,
                  identity_to_path(update.identity),
                  update.path
                ])

              live_action = String.to_atom("#{show.live_action}_#{update.live_action}")
              [%{update | path: path, live_action: live_action} | acc]
            end)

          acc =
            Enum.reduce(live_action_types.create, acc, fn action, acc ->
              path =
                build_path([page.path, show_identity, show.path, action.path])

              live_action = String.to_atom("#{show.live_action}_#{action.live_action}")
              [%{action | path: path, live_action: live_action} | acc]
            end)

          [
            %{show | path: build_path([page.path, show_identity, show.path])}
            | acc
          ]
        end)

      page = %{page | live_actions: live_actions}
      dsl = Transformer.replace_entity(dsl, [:pyro, :live_view], page)

      {dsl, errors}
    end

    defp merge_page(
           %Page{view_as: :individual, live_actions: live_actions} = page,
           {dsl, errors}
         ) do
      live_actions =
        live_actions
        |> Enum.map(&expand_live_action_defaults(&1, dsl))
        |> Enum.map(fn
          %Page.List{} = list ->
            %{list | path: build_path([page.path, list.path])}

          %Page.Show{} = show ->
            identity_path = identity_to_path(show.identity)
            %{show | path: build_path([page.path, identity_path, show.path])}

          %Page.Create{} = create ->
            %{create | path: build_path([page.path, create.path])}

          %Page.Update{} = update ->
            identity_path = identity_to_path(update.identity)
            %{update | path: build_path([page.path, identity_path, update.path])}
        end)

      page = %{page | live_actions: live_actions}
      dsl = Transformer.replace_entity(dsl, [:pyro, :live_view], page)

      {dsl, errors}
    end

    defp build_path(path) do
      path
      |> List.wrap()
      |> List.flatten()
      |> Enum.flat_map(&String.split(&1, "/", trim: true))
      |> Enum.reject(&(&1 == "/"))
      |> Enum.join("/")
      |> then(&("/" <> &1))
    end

    defp identity_to_path(identity) do
      identity
      |> List.wrap()
      |> Enum.map_join("/", &inspect/1)
    end

    defp expand_live_action_defaults(%Page.Update{load_action: nil} = live_action, dsl) do
      case filter_actions(dsl, &(&1.type == :read && &1.primary? == true)) |> List.first() do
        nil -> live_action
        %{name: name} -> %{live_action | load_action: name}
      end
      |> expand_live_action_defaults(dsl)
    end

    defp expand_live_action_defaults(%{label: :inherit} = live_action, dsl) do
      label =
        inherit_pyro_config(
          dsl,
          live_action.display_as,
          live_action.action,
          :label,
          default_label(live_action.live_action)
        )

      %{live_action | label: label}
      |> expand_live_action_defaults(dsl)
    end

    defp expand_live_action_defaults(%{live_action: name, label: nil} = live_action, dsl) do
      %{live_action | label: default_label(name)}
      |> expand_live_action_defaults(dsl)
    end

    defp expand_live_action_defaults(%{description: :inherit} = live_action, dsl) do
      description =
        inherit_pyro_config(dsl, live_action.display_as, live_action.action, :description)

      %{live_action | description: description}
      |> expand_live_action_defaults(dsl)
    end

    defp expand_live_action_defaults(live_action, _dsl), do: live_action

    defp partition_live_actions(live_actions) do
      Enum.reduce(live_actions, %{list: [], show: [], create: [], update: []}, fn
        %Page.List{} = action, acc ->
          %{acc | list: [action | acc.list]}

        %Page.Show{} = action, acc ->
          %{acc | show: [action | acc.show]}

        %Page.Create{} = action, acc ->
          %{acc | create: [action | acc.create]}

        %Page.Update{} = action, acc ->
          %{acc | update: [action | acc.update]}
      end)
    end
  end
end
