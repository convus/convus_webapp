import { Controller } from '@hotwired/stimulus'
import log from '../scripts/log' // eslint-disable-line

// Connects to data-controller="reload-page-timer"
export default class extends Controller {
  connect () {
    window.timeRemaining = parseInt(document.getElementById('reloadPageSeconds').textContent)
    window.updateReloadPageCountdown = this.updateReloadPageCountdown
    window.updateReloadPageCountdown()
  }

  updateReloadPageCountdown () {
    if (window.timeRemaining > 1) {
      window.timeRemaining -= 1
      document.getElementById('reloadPageSeconds').textContent = window.timeRemaining
      window.setTimeout(window.updateReloadPageCountdown, 1000)
    } else {
      window.location.reload()
    }
  }
}
