const defaultTheme = require('tailwindcss/defaultTheme') // eslint-disable-line

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
          primary: '#0d6efd',
          success: '#75b798', // alternative: #a3cfbb
          error: '#fecba1', // orange
          gray: {
            DEFAULT: '#adb5bd', // bootstrap grays
            100: '#f8f9fa',
            200: '#e9ecef',
            300: '#dee2e6',
            400: '#ced4da',
            500: '#adb5bd',
            600: '#6c757d',
            700: '#495057',
            800: '#343a40',
            900: '#212529'
          }
        },
        extend: {
          fontFamily: {
            serif: ['Iowan Old Style', 'Apple Garamond', 'Baskerville', 'Times New Roman', 'Droid Serif', 'Times', 'Source Serif Pro', 'serif', 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol']
          },
          maxWidth: {
            'main-content': '1024px',
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
