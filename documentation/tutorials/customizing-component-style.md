# Customizing Component Style

Finding a balance of reusability and customizability can be quite a challenge for styling components. Many patterns have emerged, each with different compromises. For example:

- [BEM](https://getbem.com/) maximizes composability and simplicity at the cost of verbosity and separating the style from the markup
- [Tailwind](https://tailwindcss.com/) maximizes simplicity and standardization at the cost of HTML density and composability
- Root class with selectors minimizes markup at the cost of complexity and composability
- [CSS in JS](https://cssinjs.org/) - Just... No.

This guide steps through some of the things to consider when it comes to choosing a strategy for _your_ use case with Pyro, and also provide context for why Pyro's default style is what it is.

## Goals

Pyro aims to make it easy to do the following with the default skin:

- Cover 90% of what you want out of the box
- Granularly tweak that custom 10%
- Override anything ad-hoc when using a component

Pyro also aims to:

- Reduce the need for hacks like `!important`
- Make those customizations maintainable
- **Not** produce HTML with a dozen classes in _every_ `td`

With the above in mind, let's look at some strategies we could apply. Please keep in mind that, while we have chosen a solution that combines Tailwind + component classes + custom variants, Pyro provides the tools for you to choose any strategy you like.

## CSS Strategies

### BEM

[BEM](https://getbem.com/) has a simple naming pattern for single classes that you apply to every element needing style. This incredibly simple system eliminates class hierarchy/inheritance concerns, and also leaves room for utility/override classes to be used so long as they are defined after the component classes.

We did not choose this system for Pyro's default style because:

- Strict adherance to the naming convention leads to heavy HTML output
  - Long class names
  - Even longer variant names
- Phoenix supports Tailwind by default
- Tailwind provides a good base for familiar standard utilities

Pyro does provide a BEM overrides file to help you get started using a BEM skin strategy. It provides no style by default, and adds BEM classes to each element of the components. This allows you to create a fully-custom skin with very little friction. Installation and configuration instructions can be found in the module docs for `Pyro.Overrides.BEM`.

Pros:

- Simple name
- Clear targeting
- No specificity conflicts
- No precedence conflicts

Cons:

- Class names can become quite long
- HTML can be heavy, especially with variants
- Unless you add conditional variants, dynamic style can be tricky
- No default styles, more work to get started

## Tailwind Strategies

### Utilities Only

Tailwind encourages a [utility-first](https://tailwindcss.com/docs/utility-first) workflow, and gives a lot of tips on how to [apply that to components](https://tailwindcss.com/docs/reusing-styles). That approach does have its challenges from a library perspective.

Utility classes have equal precedence, so overriding the skin ad-hoc can be tricky. Workarounds include:

- Using the `!` modifier, e.g. `!bg-red0500`
- Truncating/removing classes with `Pyro.Component.CSS.classes/1`
- Auto-merging with [Tails](https://hexdocs.pm/tails/Tails.html)

We did not choose this system for Pyro's default style because:

- Too many `!` hacks or complex merging solutions
- **Every** variant we design will be included in your CSS, even if unused
- Way too many classes in elements like `td` add up to heavy HTML pushed to the client

Pros:

- No names or hierarchy
- Follows Tailwind's official recommendations
- Style in markup

Cons:

- Utility precedence conflicts
- HTML heavier than `node_modules`
- **All** variants will be included in CSS
- Style in markup 🤣

### BEM + Tailwind

Tailwind can also be used with BEM classes. Pyro does not provide default styles for this strategy, but it does provide an overrides file that adds all the needed component classes to implement your own BEM style.

Details can be found at `Pyro.Overrides.BEM`.

We did not choose this system for Pyro's default style for mostly the same reasons for not using vanilla BEM.

Pros:

- Simple/clear naming/targeting
- No conflicts with utility classes

Cons:

- Class names can become quite long
- Unless you add conditional variants, dynamic style can be tricky
- No default styles, more work to get started
