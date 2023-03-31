const defaultTheme = require('tailwindcss/defaultTheme') // eslint-disable-line
const colors = require('tailwindcss/colors')

module.exports = {
  plugins: {
    'postcss-import': {},
    'tailwindcss/nesting': 'postcss-nesting',
    autoprefixer: {},
    tailwindcss: {
      content: [
        './public/*.html',
        './app/helpers/**/*.rb',
        './app/javascript/**/*.js',
        './app/views/**/*',
        './node_modules/flowbite/**/*.js' // JS interactions
      ],
      theme: {
        colors: {
          transparent: 'transparent',
          current: 'currentColor',
          white: '#ffffff',
          black: '#000000',
          primary: '#3366cc',
          success: '#75b798', // alternative: #a3cfbb
          error: '#fecba1', // orange
          bodytext: '#212529', // gray-900
          gray: colors.gray,
          slate: colors.slate
        },
        extend: {
          spacing: {
            'container-pad': '0.5rem',
            rWidth: '42rem' // width of max-w-2xl. For review-width - the width of the review table cell. Hacky :/
          },
          fontFamily: {
            serif: ['Iowan Old Style', 'Apple Garamond', 'Baskerville', 'Times New Roman', 'Droid Serif', 'Times', 'Source Serif Pro', 'serif', 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol']
          },
          maxWidth: {
            'main-content': '1024px',
            'small-container': '580px' // ~ prose width (65ch)
          }
        }
      },
      plugins: [
        require('@tailwindcss/forms'),
        require('@tailwindcss/aspect-ratio'),
        require('@tailwindcss/typography')
      ]
    }
  }
}
