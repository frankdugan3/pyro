# if statement guards you from running it in prod, which could result in loss of logs.
alias Ash.Api.Info, as: ApiInfo
alias Ash.Policy.Info, as: PolicyInfo
alias Ash.Resource.Info, as: ResourceInfo
alias Pyro.Ash.Extensions.Resource.Info, as: PI

if function_exported?(Mix, :__info__, 1) and Mix.env() == :dev do
  Logger.configure_backend(:console, device: Process.group_leader())
end
