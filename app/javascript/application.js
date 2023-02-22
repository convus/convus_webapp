// Entry point for the build script in your package.json
import '@hotwired/turbo-rails'
import './controllers'
// Import flowbite, a tailwind component library, for interactions
import 'flowbite/dist/flowbite.turbo.js'

document.addEventListener('turbo:load', () => {
  console.log('party')
})
