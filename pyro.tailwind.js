const plugin = require('tailwindcss/plugin')
const fs = require('fs')
const path = require('path')

module.exports = {
  plugins: [
    plugin(function ({ config, addVariant, matchComponents }) {
      // Add Pyro content
      const userContent = config('content', [])

      config({
        content: [
          path.join(__dirname, '../deps/pyro/lib/pyro/**/*.*ex'),
          ...userContent,
        ],
      })

      // Add variants used by Pyro
      addVariant('aria-selected', '&[aria-selected]')
      addVariant('aria-checked', '&[aria-checked]')

      // Add Heroicons
      let iconsDir = path.join(__dirname, '../deps/heroicons/optimized')
      let values = {}
      let icons = [
        ['', '/24/outline'],
        ['-solid', '/24/solid'],
        ['-mini', '/20/solid'],
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map((file) => {
          let name = path.basename(file, '.svg') + suffix
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
        })
      })
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, '')
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              '-webkit-mask': `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              'background-color': 'currentColor',
              'vertical-align': 'middle',
              display: 'inline-block',
              width: theme('spacing.5'),
              height: theme('spacing.5'),
            }
          },
        },
        { values },
      )
    }),
  ],
}
