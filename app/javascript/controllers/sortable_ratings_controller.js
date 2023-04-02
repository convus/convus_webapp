import { Controller } from '@hotwired/stimulus'
import Sortable from 'sortablejs';
import log from '../scripts/log' // eslint-disable-line

// Connects to data-controller="sortable-ratings"
export default class extends Controller {
  static bestList() {return document.getElementById("bestList") }
  static constructiveList() { document.getElementById("constructiveList")}
  static notRecommendedList() { document.getElementById("notRecommendedList")}

  connect () {
    // Hide the ranking fields
    // document.querySelectorAll('.ranking-list input[type="number"]')
    //   .forEach(el => el.classList.add('hidden'))

    window.updateRankings = this.updateRankings

    new Sortable(bestList, {
        group: 'rankingLists', // set both lists to same group
        animation: 150,
        onEnd: updateRankings
    });

    new Sortable(constructiveList, {
        group: 'rankingLists',
        animation: 150,
        onEnd: updateRankings
    });

    new Sortable(notRecommendedList, {
        group: 'rankingLists',
        animation: 150,
        onEnd: updateRankings
    });
    this.updateRankings()
  }



  updateRankings () {
    notRecommendedList.querySelectorAll(".rankInput").forEach((el, i) => {
      const newRating = -1 - i;
      el.value = newRating
    })

    const goodFirstRank = constructiveList.querySelectorAll(".rankInput").length - 1
    constructiveList.querySelectorAll(".rankInput").forEach((el, i) => {
      const newRating = goodFirstRank - i;
      el.value = newRating
    })

    const bestFirstRank = goodFirstRank + window.rankOffset + bestList.querySelectorAll(".rankInput").length
    bestList.querySelectorAll(".rankInput").forEach((el, i) => {
      const newRating = bestFirstRank - i;
      el.value = newRating
    })
  }
}
