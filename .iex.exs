if function_exported?(Mix, :__info__, 1) and Mix.env() == :dev do
  Logger.configure_backend(:console, device: Process.group_leader())
end
