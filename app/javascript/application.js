// Entry point for the build script in your package.json
import '@hotwired/turbo-rails'
import './controllers'
import BrowserExtensionScript from './scripts/browser_extension_script.js'
// Import flowbite, a tailwind component library, for interactions
import 'flowbite/dist/flowbite.turbo.js'
import { TimeParser, PeriodSelector, Pagination } from 'tranzito_utils_js'
// import TimeParser from './scripts/time_parser'

import log from './scripts/log' // eslint-disable-line

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

const pageWidth = window.outerWidth
const enableFullscreenTableOverflow = () => {
  document.querySelectorAll('.full-screen-table table').forEach(el => {
    const tableWidth = el.offsetWidth
    if (tableWidth > pageWidth) {
      console.log('overflown')
      el.closest('.full-screen-table').classList.add('full-screen-table-overflown')
    }
  })
}

const setMaxWidths = () => {
  if (pageWidth < 501) {
    document.querySelectorAll('.maxWScreen')
      .forEach(el => {
        // 8px on either side of padding
        el.style.maxWidth = `${pageWidth - 16}px`
      })
  }
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

  enableToggleChecks()
  enableFullscreenTableOverflow()
  setMaxWidths()

  // When JS is enabled, some things should be hidden and some things should be shown
  document.querySelectorAll('.hiddenNoJs').forEach(el => el.classList.remove('hiddenNoJs'))
  document.querySelectorAll('.hiddenOnJs').forEach(el => el.classList.add('hidden'))
})
