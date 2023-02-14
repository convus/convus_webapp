const defaultTheme = require('tailwindcss/defaultTheme')

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
        './app/views/**/*.erb'
      ],
      theme: {
        fontFamily: {
          serif: ["Iowan Old Style", "Apple Garamond", "Baskerville", "Times New Roman", "Droid Serif", "Times", "Source Serif Pro", "serif", "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"]
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
