// Entry point for the build script in your package.json
import '@hotwired/turbo-rails'
import './controllers'
import BrowserExtensionScript from './scripts/browser_extension_script.js'
// Import flowbite, a tailwind component library, for interactions
import 'flowbite/dist/flowbite.turbo.js'
import { TimeParser, PeriodSelector, Pagination } from 'tranzito_utils_js'

const enableFullscreenTableOverflow = () => {
  const pageWidth = window.innerWidth;
  document.querySelectorAll('.full-screen-table table').forEach(el => {
    const tableWidth = el.offsetWidth;
    if (tableWidth > pageWidth) {
      console.log("overflown")
      el.closest(".full-screen-table").classList.add("full-screen-table-overflown")
    }
  })
}

document.addEventListener('turbo:load', () => {
  if (document.getElementById('timeSelectionBtnGroup')) {
    const periodSelector = new PeriodSelector()
    periodSelector.init()
  }

  if (!window.timeParser) window.timeParser = new TimeParser()
  window.timeParser.localize()

  window.pagination = new Pagination()
  window.pagination.init()

  if (document.getElementById('review-menu')) {
    BrowserExtensionScript()
  }

  enableFullscreenTableOverflow();
})
