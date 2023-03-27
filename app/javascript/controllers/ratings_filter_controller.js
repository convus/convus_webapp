import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select/dist/js/tom-select.popular.js"
import log from '../scripts/log' // eslint-disable-line

// Connects to data-controller="ratings-filter"
export default class extends Controller {

  connect() {
    this.filterSelect = new TomSelect('#filters_select', { plugins: ["remove_button"]})
    log.debug(this.filterSelect.value)
    this.filterSelect.on('change', this.updateFilterList)
  }

  updateFilterList(value) {

    // Should be defined in this class, rather than in this - but... not working
    const form = document.getElementById('filters_select').closest('form')
    form.submit()
  }
}
