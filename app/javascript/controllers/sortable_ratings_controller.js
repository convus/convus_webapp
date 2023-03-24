import { Controller } from "@hotwired/stimulus"
import log from '../scripts/log' // eslint-disable-line

// Connects to data-controller="sortable-ratings"
export default class extends Controller {
  connect() {
    log.debug("this will be sortable, sometime")
  }
}
