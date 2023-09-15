import { Controller } from '@hotwired/stimulus'
import log from '../scripts/log' // eslint-disable-line

// Connects to data-controller="admin-current-header"
export default class extends Controller {
  // Simple hack to create a dropdown that submits on change
  connect () {
    const updatePage = this.updatePage // eslint-disable-line
    document.querySelectorAll('.updateOnChange')
      .forEach(el => el.addEventListener('change', updatePage))
  }

  updatePage (event) {
    const updateUrl = event.target.getAttribute('data-updateUrl')
    location.href = updateUrl.replace('UpdateThis', event.target.value) // eslint-disable-line
  }
}
