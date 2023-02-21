// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

let plugin = require('tailwindcss/plugin')

module.exports = {
  darkMode: 'class',
  content: [
    './js/**/*.js',
    '../dev/component_previewer/*_web.ex',
    '../dev/component_previewer/**/*.*ex',
    '../lib/phlegethon/**/*.*ex',
  ],
  theme: {
    extend: {
      colors: {
        ...require('./tailwind.phlegethon.colors.json'),
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    plugin(({ addVariant }) =>
      addVariant('phx-no-feedback', [
        '&.phx-no-feedback',
        '.phx-no-feedback &',
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-click-loading', [
        '&.phx-click-loading',
        '.phx-click-loading &',
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-submit-loading', [
        '&.phx-submit-loading',
        '.phx-submit-loading &',
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-change-loading', [
        '&.phx-change-loading',
        '.phx-change-loading &',
      ]),
    ),
  ],
}
