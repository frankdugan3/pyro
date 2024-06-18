# Class Variants

## Solving Tailwind Utility Conflicts

If you are exclusively using Tailwind utilities in your components, you may want to "merge" them with a tool that removes conflicting classes. Fortunately, there are a few options out there:

- [Tails.classes/1](https://hexdocs.pm/tails/Tails.html#classes/1)
  ```elixir
  use Pyro, css_normalizer: &Tails.classes/1
  ```
- [Turboprop.Merge.merge/2](https://hexdocs.pm/turboprop/Turboprop.Merge.html#merge/2)
  ```elixir
  use Pyro, css_normalizer: &Turboprop.Merge.merge(&1)
  ```
