import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select/dist/js/tom-select.popular.js"
import log from '../scripts/log' // eslint-disable-line

// Connects to data-controller="ratings-filter"
export default class extends Controller {

  connect() {
    if (document.getElementById('filters_select')) {
      this.filterSelect = new TomSelect('#filters_select', { plugins: ["remove_button"]})
      this.filterSelect.on('change', this.updateFilterList)
    } else {
      window.formSubmit = this.formSubmit
      document.querySelectorAll('.submitOnChange')
        .forEach(el => el.addEventListener('change', formSubmit))
    }
  }

  formSubmit() {
    log.debug('-------')
    // Should be defined in this class, rather than in this - but... couldn't figure it out
    document.getElementById('ratingsFilterForm').submit()
  }

  updateFilterList(value) {
    // Check if the new value is a user value - if it is, remove any previous user values
    // ... then submit after change
  }
}
