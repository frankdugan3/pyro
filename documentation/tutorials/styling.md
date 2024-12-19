# Styling

Pyro takes a unqiue approach to templating components, an approach which requires implementations for each CSS strategy supported by the component. This allows abstractions (props, calculations, state management, etc.) to be shared, yet provides flexibility for rendering and validation of props. Here's an example:

```elixir
token :color do
  variants ["red", "yellow"]
  layered_css do
    modifier "is-"
  end
  framework :tailwind do
    variant {"red", "bg-red-500 text-white"}
    variant {"yellow", "bg-yellow-500 text-black"}
  end
end
component :button do
  prop :replace, :boolean
  prop :confirm, :string
  prop :color, :string,
    variant: true,
    token: :color
    # default: {:token, :color},
    # values: {:token, :color}
  prop :rest, :global
  slot :inner_block, required: true, doc: "the content of the button"
  block :button, "%{href: href} = assigns" do
    variants [:color, :size, :variant]
    assign [:replace, :confirm, :rest]
    assign "data-confirm", {"!!", :confirm}
    el :spinner, {:component, :spinner} do
      directive :if, :loading
      assign :size
    end
    el :icon, {:component, :icon} do
      assign [:icon_name]
    end
    render_slot :inner_block
  end
end
```

## Strategies

The table below outlines the better known strategies for CSS, as well as the support status within Pyro. Strategies that are not planned are welcome to implemented via PRs.

| Name                                                                | Frameworks |   Status    |
| ------------------------------------------------------------------- | ---------- | :---------: |
| LayeredCSS                                                          | Tailwind   | Implemented |
| [BEM](https://getbem.com/)                                          | Tailwind   | Implemented |
| Utility-First                                                       | Tailwind   |   Planned   |
| [CubeCSS](https://cube.fyi/)                                        |            |             |
| [ITCSS](https://itcss.io/)                                          |            |             |
| [Atomic Design](https://bradfrost.com/blog/post/atomic-web-design/) |            |             |
| [SMACSS](https://smacss.com/)                                       |            |             |
| [OOCSS](http://oocss.org/)                                          |            |             |

## Native Layers with Tailwind 3

Tailwind 4 will use native CSS layers. For now, we can massage Tailwind 3 into using native layers like this:

```css
/* app.css */
@import 'tailwindcss/base' layer(app-base);
@import './base.css' layer(app-base);

@import 'tailwindcss/components' layer(app-components);
@import './components.css' layer(app-components);

@import './variants.css' layer(app-variants);

@import 'tailwindcss/utilities' layer(app-utilities);
@import './utilities.css' layer(app-utilities);
```

## Themes

Check out:

- https://uicolors.app/create
- https://gradient.page/tools/shadcn-ui-theme-generator
