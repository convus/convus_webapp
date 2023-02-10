// Entry point for the build script in your package.json
import '@hotwired/turbo-rails'
import jQuery from 'jquery'
import './controllers'

document.addEventListener('turbo:load', () => {

})

window.$ = window.jQuery = jQuery
