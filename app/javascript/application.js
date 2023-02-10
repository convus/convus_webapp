// Entry point for the build script in your package.json
import '@hotwired/turbo-rails'
import jQuery from 'jquery'
import './controllers'

document.addEventListener('turbo:load', () => {
  console.log("party")
})

window.$ = window.jQuery = jQuery
