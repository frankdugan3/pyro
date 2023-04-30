---
name: Component Revision
about: Propose a revision for an existing component.
title: 'Component RFC: '
labels: component, enhancement
assignees: ''
---

**Pre-check**

This component revision proposal:

- [ ] Is not a duplicate of an existing issue
- [ ] Does not require 3rd party JS to implement
- [ ] Considers mobile-friendliness
- [ ] Does not cause accessibility problems

**Describe the use case/problems solved for this component revision**
A clear and concise description of the use case fulfilled or problems solved by this component revision.

**Demonstrate any changes to the component's API**

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
Add any other context/screenshots of the revision here.
