import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="alert"
export default class extends Controller {
  close () {
    this.element.classList.add('opacity-0', 'scale-95')
    setTimeout(() => {
      this.element.classList.add('hidden')
    }, 300)
  }
}
