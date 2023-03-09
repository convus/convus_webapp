// Entry point for the build script in your package.json
import '@hotwired/turbo-rails'
import './controllers'
import BrowserExtensionScript from './scripts/browser_extension_script.js'
// Import flowbite, a tailwind component library, for interactions
import 'flowbite/dist/flowbite.turbo.js'
import { TimeParser, PeriodSelector, Pagination } from 'tranzito_utils_js'

// TODO: rewrite without jquery
// enableFullscreenTableOverflow() {
//   const pageWidth = $(window).width();
//   $(".full-screen-table table").each(function(index) {
//     const $this = $(this);
//     if ($this.outerWidth() > pageWidth) {
//       $this
//         .parents(".full-screen-table")
//         .addClass("full-screen-table-overflown");
//     }
//   });
// }

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

  // enableFullscreenTableOverflow();
  document.getElementById('review_timezone').value = Intl.DateTimeFormat().resolvedOptions().timeZone

})
