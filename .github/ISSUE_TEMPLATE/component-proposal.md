---
name: Component Proposal
about: Propose a new component idea.
title: 'Component: '
labels: component, enhancement
assignees: ''
---

**Pre-check**

This component proposal:

- [ ] Is not a duplicate of an existing issue
- [ ] Does not require 3rd party JS to implement
- [ ] Considers mobile-friendliness
- [ ] Does not cause accessibility problems

**Describe the use case for this component**
A clear and concise description of the use case this component will fulfill.

**Demonstrate the component's API**

```heex
<.some_component a-prop={@value} />
```

**Component mockup (optional)**

```elixir
defmodule Pyro.Components.SomeComponent do
  use Pyro.Component

  def some_component(assigns) do
    ~H"""
    """
  end
end
```

**Additional context**
Add any other context/screenshots of the idea here.
