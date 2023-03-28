import { Controller } from '@hotwired/stimulus'
// import TomSelect from 'tom-select/dist/js/tom-select.popular.js'
import log from '../scripts/log' // eslint-disable-line

// Connects to data-controller="ratings-filter"
export default class extends Controller {
  connect () {
    const formSubmit = this.formSubmit // eslint-disable-line
    document.querySelectorAll('.submitOnChange')
      .forEach(el => el.addEventListener('change', formSubmit))
  }

  formSubmit () {
    // Should be defined in this class, rather than in this - but... couldn't figure it out
    document.getElementById('ratingsFilterForm').submit()
  }
}
