import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs'
import log from '../scripts/log' // eslint-disable-line

// Connects to data-controller="sortable-ratings"
export default class extends Controller {
  // Standard isn't happy with the static methods, so pretend they're globals
  /* global bestList, constructiveList, notRecommendedList */
  static bestList () { document.getElementById('bestList') }
  static constructiveList () { document.getElementById('constructiveList') }
  static notRecommendedList () { document.getElementById('notRecommendedList') }

  connect () {
    // Hide the ranking fields
    document.querySelectorAll('.ranking-list input[type="number"]')
      .forEach(el => el.classList.add('hidden'))

    Sortable.create(bestList, {
      group: 'rankingLists',
      animation: 150,
      onEnd: this.updateRankings
    })

    Sortable.create(constructiveList, {
      group: 'rankingLists',
      animation: 150,
      onEnd: this.updateRankings
    })

    Sortable.create(notRecommendedList, {
      group: 'rankingLists',
      animation: 150,
      onEnd: this.updateRankings
    })
  }

  updateRankings () {
    notRecommendedList.querySelectorAll('.rankInput').forEach((el, i) => {
      const newRating = -1 - i
      el.value = newRating
    })

    const goodFirstRank = constructiveList.querySelectorAll('.rankInput').length
    constructiveList.querySelectorAll('.rankInput').forEach((el, i) => {
      const newRating = goodFirstRank - i
      el.value = newRating
    })

    const bestFirstRank = goodFirstRank + window.rankOffset + bestList.querySelectorAll('.rankInput').length
    bestList.querySelectorAll('.rankInput').forEach((el, i) => {
      const newRating = bestFirstRank - i
      el.value = newRating
    })
  }
}
