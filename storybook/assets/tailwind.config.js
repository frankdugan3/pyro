const path = require('path')

module.exports = {
  important: '.pyro-storybook-web',
  darkMode: 'class',
  content: [
    './js/**/*.js',
    '../lib/pyro_storybook_web.ex',
    '../lib/pyro_storybook_web/**/*.*ex',
    '../storybook/**/*.*exs',
    '../../lib/pyro/**/*.*ex',
  ],
  plugins: [
    require('@tailwindcss/forms'),
    require(path.join(__dirname, '../../assets/js/tailwind-plugin.js'))({
      heroIconsPath: path.join(__dirname, '../deps/heroicons/optimized'),
      addBase: true,
    }),
  ],
}
