if function_exported?(Mix, :__info__, 1) and Mix.env() == :dev do
  # if statement guards you from running it in prod, which could result in loss of logs.
  Logger.configure_backend(:console, device: Process.group_leader())
end

alias Pyro.Resource.Info, as: UI
alias Ash.Resource.Info, as: ResourceInfo
alias Ash.Policy.Info, as: PolicyInfo
alias Ash.Api.Info, as: ApiInfo
alias ComponentPreviewer.Ash.User
