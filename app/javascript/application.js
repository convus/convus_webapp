// Entry point for the build script in your package.json
import '@hotwired/turbo-rails'
import './controllers'
import BrowserExtensionScript from './scripts/browser_extension_script.js'
// Import flowbite, a tailwind component library, for interactions
import 'flowbite/dist/flowbite.turbo.js'
import { TimeParser, PeriodSelector, Pagination } from 'tranzito_utils_js'

import log from './scripts/log' // eslint-disable-line

const enableFullscreenTableOverflow = () => {
  const pageWidth = window.innerWidth
  document.querySelectorAll('.full-screen-table table').forEach(el => {
    const tableWidth = el.offsetWidth
    if (tableWidth > pageWidth) {
      console.log('overflown')
      el.closest('.full-screen-table').classList.add('full-screen-table-overflown')
    }
  })
}

const toggleChecks = (event) => {
  const checked = event.target.checked
  event.target.closest('.toggleChecksWrapper')
    .querySelectorAll('.toggleableCheck').forEach(el => {
      el.checked = checked
    })
}

const enableToggleChecks = () => {
  document.querySelectorAll('.toggleChecks')
    .forEach(el => el.addEventListener('change', toggleChecks))
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

  if (document.getElementById('rating-menu')) {
    BrowserExtensionScript()
  }

  enableFullscreenTableOverflow()
  enableToggleChecks()

  // When JS is enabled, some things should be hidden and some things should be shown
  document.querySelectorAll('.hiddenNoJs').forEach(el => el.classList.remove('hiddenNoJs'))
  document.querySelectorAll('.hiddenOnJs').forEach(el => el.classList.add('hidden'))
})
