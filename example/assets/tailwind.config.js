// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const path = require('path')

module.exports = {
  darkMode: 'class',
  content: [
    './js/**/*.js',
    '../lib/example_web.ex',
    '../lib/example_web/**/*.*ex',
    '../../lib/pyro/**/*.*ex',
  ],
  theme: {
    extend: {
      colors: {
        brand: '#FD4F00',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require(path.join(__dirname, '../../assets/js/tailwind-plugin.js'))({
      heroIconsPath: path.join(__dirname, '../deps/heroicons/optimized'),
      addBase: true,
    }),
  ],
}
