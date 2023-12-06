const plugin = require('tailwindcss/plugin')

module.exports = plugin(function ({
  addVariant,
  addBase,
  addComponents,
  theme,
}) {
  const nonColors = ['inherit', 'current', 'transparent', 'black', 'white']
  const variantColors = Object.keys(theme('colors')).filter(
    (color) => !nonColors.includes(color),
  )

  addVariant('phx-no-feedback', ['.phx-no-feedback&', '.phx-no-feedback &'])
  addVariant('phx-click-loading', [
    '.phx-click-loading&',
    '.phx-click-loading &',
  ])
  addVariant('phx-submit-loading', [
    '.phx-submit-loading&',
    '.phx-submit-loading &',
  ])
  addVariant('phx-change-loading', [
    '.phx-change-loading&',
    '.phx-change-loading &',
  ])
  addVariant('aria-selected', '&[aria-selected]')
  addVariant('aria-checked', '&[aria-checked]')
  addBase({
    '::selection, ::-moz-selection': {
      '@apply text-white bg-sky-500 bg-opacity-100': {},
    },

    ':root': { '--scrollbar-width': '0.5rem' },

    // Firefox
    '*': {
      'scrollbar-width': 'auto',
      'scrollbar-height': 'auto',
      'scrollbar-color': 'theme(colors.sky.500) transparent',
    },

    // Chrome, Edge, and Safari
    '*::-webkit-scrollbar': {
      width: 'var(--scrollbar-width)',
      height: 'var(--scrollbar-width)',
    },
    '*::-webkit-scrollbar-button': { '@apply bg-transparent h-0 w-0': {} },
    '::-webkit-scrollbar-corner': { '@apply bg-transparent': {} },
    '*::-webkit-scrollbar-track': { background: 'transparent' },
    '*::-webkit-scrollbar-track-piece': { '@apply bg-transparent': {} },
    '*::-webkit-scrollbar-thumb': {
      '@apply bg-sky-500 border-none rounded-full': {},
    },

    var: {
      '@apply not-italic rounded font-mono text-sm font-semibold px-2 py-px mx-px bg-slate-900 text-white dark:bg-white dark:text-slate-900':
        {},
    },

    'html, body': {
      '@apply bg-white text-slate-900 dark:text-white dark:bg-gradient-to-tr dark:from-slate-900 dark:to-slate-800':
        {},
    },
  })
  addComponents({
    // Core.back
    '.pyro-back': {
      '@apply font-black border-b-2 border-dotted text-slate-900 border-slate-900 dark:text-white dark:border-white hover:text-sky-500 hover:border-sky-500 active:text-sky-500 active:border-sky-500 active:border-solid':
        {},
      '&__icon': { '@apply w-3 h-3 stroke-current align-baseline': {} },
    },

    // Core.button
    '.pyro-btn': {
      '@apply shadow-md shadow-slate-900/5 dark:shadow-slate-300/5 font-semibold text-center inline-block cursor-pointer disabled:cursor-not-allowed disabled:opacity-50 appearance-none select-none px-2 whitespace-nowrap active:opacity-50 relative':
        {},
      '&:not(:disabled)': { '@apply hover:scale-105': {} },
      '&.pyro--xs': {
        '@apply text-xs': {},
        '&.pyro-btn--outline, &.pyro-btn--inverted': {
          '@apply border border-solid': {},
        },
      },
      '&.pyro--sm': {
        '@apply text-sm': {},
        '&.pyro-btn--outline, &.pyro-btn--inverted': {
          '@apply border border-solid': {},
        },
      },
      '&.pyro--md': {
        '@apply text-base': {},
        '&.pyro-btn--outline, &.pyro-btn--inverted': { '@apply border-2': {} },
        '& .pyro-btn__icon': { '@apply h-5 w-5': {} },
      },
      '&.pyro--lg': {
        '@apply text-lg': {},
        '&.pyro-btn--outline, &.pyro-btn--inverted': { '@apply border-2': {} },
        '& .pyro-btn__icon': { '@apply h-5 w-5': {} },
      },
      '&.pyro--xl': {
        '@apply text-xl': {},
        '&.pyro-btn--outline, &.pyro-btn--inverted': { '@apply border-2': {} },
        // '& .pyro-btn__icon': { '@apply h-6 w-6"': {} },
      },
      '&--rounded': { '@apply rounded': {} },
      // '&--square': { '@apply ': {} },
      '&--pill': { '@apply rounded-full': {} },
      '&__ping': {
        '@apply block absolute rounded-full w-3 h-3 bg-red-500': {},
      },
      '&--pill &__ping': { '@apply -top-1 -right-1': {} },
      '&:not(&--pill) &__ping': { '@apply -top-1.5 -right-1.5': {} },
      ...variantColors.reduce((acc, color) => {
        let textColor = 'white'
        if (
          [
            'orange',
            'amber',
            'yellow',
            'lime',
            'green',
            'emerald',
            'teal',
            'cyan',
          ].includes(color)
        ) {
          textColor = 'black'
        }
        acc[`&--inverted.pyro--${color}`] = {
          [`@apply border-${color}-500 text-${color}-500 bg-${textColor} hover:bg-${color}-500 hover:text-${textColor}`]:
            {},
        }
        acc[`&--outline.pyro--${color}`] = {
          [`@apply border-${color}-500 text-${color}-500`]: {},
        }
        acc[`&--solid.pyro--${color}`] = {
          [`@apply bg-${color}-500 text-${textColor}`]: {},
        }
        return acc
      }, {}),
    },

    // Core.error
    '.pyro-error': {
      '@apply phx-no-feedback:hidden flex gap-1 text-sm leading-6 text-red-600 dark:text-red-500':
        {},
      '&__icon': { '@apply h-5 w-5 flex-none inline': {} },
    },

    // Core.flash
    '.pyro-flash': {
      '@apply hidden w-80 sm:w-96 rounded p-3 relative z-50 ring-1 shadow-md shadow-slate-900/5 dark:shadow-slate-300/5':
        {},
      ...variantColors.reduce((acc, color) => {
        acc[`&.pyro--${color}`] = {
          [`@apply bg-${color}-100 text-${color}-900 ring-${color}-500 fill-${color}-900 dark:bg-${color}-900 dark:text-${color}-100 dark:ring-${color}-500 dark:fill-${color}-100`]:
            {},
        }
        return acc
      }, {}),
      '&__control': {
        '@apply grid grid-cols-[1fr,auto] items-center gap-1': {},
      },
      '&__close_icon': {
        '@apply h-5 w-5 stroke-current opacity-40 block -mr-2': {},
      },
      '&:hover .pyro-flash__close_icon': {
        '@apply opacity-70': {},
      },
      '&__message': { '@apply text-sm whitespace-pre-wrap': {} },
      '&__progress': { '@apply border border-black/25': {} },
      '&__title': {
        '@apply flex items-center gap-1.5 text-sm font-semibold leading-6': {},
      },
    },

    // Core.flash_group
    '.pyro-flash_group': { '@apply absolute top-2 right-2 grid gap-2': {} },

    // Core.header
    '.pyro-header': {
      '&.pyro--actions': {
        '@apply flex items-center justify-between gap-6': {},
      },
      '&:not(.pyro--actions) &__title': { '@apply text-center': {} },
      '&__title': {
        '@apply text-lg font-semibold leading-8 text-slate-800 dark:text-slate-50':
          {},
      },
      '&__subtitle': {
        '@apply mt-2 text-sm leading-6 text-slate-600 dark:text-slate-200': {},
      },
      '&__actions': { '@apply flex gap-2': {} },
    },

    // Core.icon
    '.pyro-icon': { '@apply h-4 w-4 inline-block align-text-bottom': {} },

    // Core.input
    '.pyro-input': {
      '@apply grid gap-1 content-start': {},
      '&__input': {
        '@apply rounded-lg block w-full border-slate-300 py-[7px] px-[11px] sm:text-sm sm:leading-6 bg-transparent text-slate-900 dark:text-white focus:outline-none focus:ring-4 phx-no-feedback:border-slate-300 phx-no-feedback:focus:border-slate-400 phx-no-feedback:focus:ring-slate-800/5':
          {},
        '&[type="checkbox"]': {
          '@apply w-auto rounded text-sky-500 dark:text-sky-500': {},
        },
        '&[type="select"]': { '@apply py-2 px-3': {} },
        '&.pyro--errors': {
          '@apply border-red-600 focus:border-red-600 focus:ring-red-600/10 dark:border-red-500 dark:focus:border-red-500 dark:focus:ring-red-500/25':
            {},
        },
        '&:not(.pyro--errors)': {
          '@apply border-slate-300 dark:border-slate-700 focus:border-slate-500 focus:ring-slate-800/5 dark:focus:border-slate-50 dark:focus:ring-slate-50/25':
            {},
        },
        '&_check_label': {
          '@apply flex items-center gap-2 text-sm leading-6 text-slate-800 dark:text-slate-100 font-semibold':
            {},
        },
        '&_datetime_zoned_wrapper': {
          '@apply grid gap-2 text-sm content-center items-center grid-cols-[1fr,auto] justify-start':
            {},
        },
      },
      '&__description': {
        '@apply text-xs text-slate-600 dark:text-slate-400': {},
      },
    },
    'textarea.pyro-input__input': { '@apply min-h-[6rem]': {} },

    // Core.label
    '.pyro-label': {
      '@apply block text-sm text-left font-semibold leading-6 text-slate-800 dark:text-slate-100':
        {},
    },

    // Core.simple_form
    '.pyro-simple_form': {
      '@apply grid gap-2 bg-white text-slate-900 dark:text-white dark:bg-gradient-to-tr dark:from-slate-900 dark:to-slate-800':
        {},
      '&_form__actions': {
        '@apply mt-2 flex items-center justify-between gap-6': {},
      },
    },

    // Core.list
    '.pyro-list': {
      '@apply grid grid-cols-[auto,1fr] gap-2': {},
      '&__dt': { '@apply font-black leading-6': {} },
      // '&__dd': { '@apply ': {} },
    },

    // Core.modal
    '.pyro-modal': { '@apply relative z-50 hidden': {} },

    // Core.table
    '.pyro-table': {
      '@apply w-full': {},
      '&__thead': { '@apply text-left text-[0.8125rem] leading-6': {} },
      '&__th_label': { '@apply p-0 pb-4 pr-6 font-normal': {} },
      '&__th_action': { '@apply relative p-0 pb-4': {} },
      '&__tbody': {
        '@apply relative divide-y divide-slate-100 border-t border-slate-200 text-sm leading-6':
          {},
      },
      '&__tr': { '@apply relative hover:bg-slate-50': {} },
      '&__td': { '@apply p-0': {} },
      '&__action': {
        '@apply relative ml-4 font-semibold leading-6 hover:text-slate-700': {},
        '&_wrapper': {
          '@apply relative whitespace-nowrap py-4 text-right text-sm font-medium':
            {},
        },
        '&_td': { '@apply p-0 w-14': {} },
      },
    },

    // Core.a
    '.pyro-a': {
      '@apply font-black border-b-2 border-dotted text-slate-900 border-slate-900 dark:text-white dark:border-white hover:text-sky-500 hover:border-sky-500 active:text-sky-500 active:border-sky-500 active:border-solid':
        {},
    },

    // Core.code
    '.pyro-code': {
      '@apply whitespace-pre-wrap p-4 rounded relative shadow-md shadow-slate-900/5 dark:shadow-slate-300/5':
        {},
      '&__copy': { '@apply absolute top-1 right-1': {} },
    },

    // Core.nav_link
    '.pyro-nav_link': {
      '@apply font-black border-b-2 border-dotted text-slate-900 border-slate-900 dark:text-white dark:border-white hover:text-sky-500 hover:border-sky-500 active:text-sky-500 active:border-sky-500 active:border-solid':
        {},
      '&.current': {
        '@apply border-solid cursor-default text-slate-900 dark:text-white border-slate-900 dark:border-white':
          {},
      },
    },

    // Core.progress
    '.pyro-progress': {
      '@apply rounded w-full': {},
      '&.pyro--xs': { '@apply h-1': {} },
      '&.pyro--sm': { '@apply h-2': {} },
      '&.pyro--md': { '@apply h-4': {} },
      '&.pyro--lg': { '@apply h-6': {} },
      '&.pyro--xl': { '@apply h-8': {} },
      '&::-webkit-progress-bar': { '@apply rounded': {} },
      '&::-webkit-progress-value': { '@apply rounded': {} },
      '&::-moz-progress-bar': { '@apply rounded': {} },
      ...variantColors.reduce((acc, color) => {
        acc[`&.pyro--${color}, &.pyro--${color}::-webkit-progress-bar`] = {
          [`@apply bg-${color}-100 dark:bg-${color}-900`]: {},
        }

        acc[`&.pyro--${color}::-webkit-progress-value`] = {
          [`@apply bg-${color}-500`]: {},
        }

        acc[`&.pyro--${color}::-moz-progress-bar`] = {
          [`@apply bg-${color}-500`]: {},
        }
        return acc
      }, {}),
    },

    // Core.spinner
    '.pyro-spinner': {
      '@apply animate-spin inline-block align-baseline': {},
      '&.pyro--xs': { '@apply h-2 w-2': {} },
      '&.pyro--sm': { '@apply h-3 w-3': {} },
      '&.pyro--md': { '@apply h-3 w-3': {} },
      '&.pyro--lg': { '@apply h-3 w-3': {} },
      '&.pyro--xl': { '@apply h-4 w-4': {} },
      '& circle': { '@apply opacity-25': {} },
      '& path': { '@apply opacity-75': {} },
    },

    // Core.tooltip
    '.pyro-tooltip': {
      '@apply hover:relative inline-block select-none hover:bg-sky-500 rounded cursor-help':
        {},
      '&__tooltip': {
        '@apply absolute invisible select-none normal-case block z-10 shadow-md shadow-slate-900/5 dark:shadow-slate-300/5':
          {},
      },
      '&:hover .pyro-tooltip__tooltip': { '@apply visible': {} },
      '&__text': {
        '@apply bg-sky-500 text-white min-w-[20rem] p-2 rounded text-sm font-normal whitespace-pre':
          {},
      },
    },

    // Autocomplete
    '.pyro-autocomplete': {
      '@apply grid gap-1 content-start': {},
      '&__listbox': {
        '@apply absolute z-10 grid content-start top-0 left-0 sm:text-sm sm:leading-6 bg-white text-slate-900 dark:bg-gradient-to-tr dark:from-slate-900 dark:to-slate-800 dark:text-white border border-slate-300 rounded-lg shadow-lg':
          {},
        '&_option': {
          '@apply aria-selected:bg-sky-500 aria-selected:text-white py-1 px-2 rounded-lg':
            {},
          '&:not(.pyro--results)': { '@apply cursor-default': {} },
          '&.pyro--results': {
            '@apply cursor-pointer hover:bg-slate-300 hover:text-slate-900': {},
          },
        },
      },
    },

    // SmartForm
    '.pyro-smart_form': {
      '@apply grid gap-2': {},
      '&__actions': {
        '@apply mt-2 flex items-center justify-between gap-6': {},
      },
      '&__render_field__group': {
        '@apply grid col-span-full text-center gap-2 p-2 border border-solid rounded-lg border-slate-300 dark:border-slate-700':
          {},
        '&_label': {
          '@apply font-black col-span-full': {},
        },
      },
    },
  })
})
