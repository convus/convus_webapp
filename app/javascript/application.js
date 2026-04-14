import '@hotwired/turbo-rails'
import 'controllers'
import 'chartkick'
import 'Chart.bundle'
import TimeLocalizer from '@bikeindex/time-localizer'

const toggleChecks = (event) => {
  const checked = event.target.checked
  event.target.closest('.toggleChecksWrapper')
    .querySelectorAll('.toggleableCheck').forEach(el => {
      el.checked = checked
    })
}

const enableToggleChecks = () => {
  document.querySelectorAll('.toggleChecks')
    .forEach(el => el.addEventListener('change', toggleChecks))
}

const pageWidth = window.outerWidth
const enableFullscreenTableOverflow = () => {
  document.querySelectorAll('.full-screen-table table').forEach(el => {
    const tableWidth = el.offsetWidth
    if (tableWidth > pageWidth) {
      el.closest('.full-screen-table').classList.add('full-screen-table-overflown')
    }
  })
}

const setMaxWidths = () => {
  if (pageWidth < 501) {
    document.querySelectorAll('.maxWScreen')
      .forEach(el => {
        el.style.maxWidth = `${pageWidth - 16}px`
      })
  }
}

// Internal
const elementsFromSelectorOrElements = (selOrEl) => {
  if (typeof (selOrEl) === 'string') {
    return document.querySelectorAll(selOrEl)
  } else {
    return [selOrEl].flat()
  }
}

// toggle can be: [true, 'hide', 'show']
const elementsCollapse = (selOrEl, toggle = true) => {
  const els = elementsFromSelectorOrElements(selOrEl)
  if (toggle === true) {
    toggle = els[0]?.classList.contains('hidden') ? 'show' : 'hide'
  }
  if (toggle === 'show') {
    els.forEach(el => el.classList.remove('hidden'))
  } else {
    els.forEach(el => el.classList.add('hidden'))
  }
}

const expandSiblingsEllipse = (event) => {
  event.preventDefault()
  const target = event.currentTarget
  const parent = target.parentElement
  parent.querySelectorAll('.hidden').forEach(el => elementsCollapse(el, 'show'))
  elementsCollapse(target, 'hide')
}

// It's impossible to redirect_to anchor locations with Hotwire (because of :see_other)
// So: this adds an event listener to store anchor locations prior to form submission
// and scrolls to the stored location
const scrollToStoredLocation = () => {
  const storedAnchor = localStorage.getItem('storedAnchorLocation')
  if (storedAnchor) {
    window.location.hash = storedAnchor
    localStorage.removeItem('storedAnchorLocation')
  }

  document.querySelectorAll('.button_to')
    .forEach(el => {
      if (buttonToAnchorTarget(el)) {
        el.addEventListener('submit', storeAnchorLocation)
      }
    })
}

const buttonToAnchorTarget = (el) => {
  const result = el?.action?.match(/#.*/)
  return result && result[0]
}

const storeAnchorLocation = (event) => {
  localStorage.setItem('storedAnchorLocation', buttonToAnchorTarget(event.target))
  return true
}

const BrowserExtensionScript = () => {
  const toggleTopicsVisible = (isVisible) => {
    window.topicsVisibile = isVisible
    if (window.topicsVisibile) {
      document.getElementById('field-group-topics').classList.remove('hidden')
    } else {
      document.getElementById('field-group-topics').classList.add('hidden')
    }
  }

  const toggleMenu = (e) => {
    e.preventDefault()
    const menuBtn = document.getElementById('rating-menu-btn')
    const menu = document.getElementById('rating-menu')
    if (menu.classList.contains('active')) {
      menu.classList.add('hidden')
      menu.classList.remove('active')
      menuBtn.classList.remove('active')
    } else {
      menu.classList.remove('hidden')
      menu.classList.add('active')
      menuBtn.classList.add('active')
    }
  }
  const updateMenuCheck = (e) => {
    const el = e.target
    const fieldId = el.getAttribute('data-target-id')

    if (fieldId === 'field-group-topics') {
      toggleTopicsVisible(el.checked)
    } else if (el.checked) {
      document.getElementById(fieldId).classList.remove('hidden')
    } else {
      document.getElementById(fieldId).classList.add('hidden')
    }
  }

  document.getElementById('rating-menu-btn').addEventListener('click', toggleMenu)
  document.querySelectorAll('#rating-menu .form-control-check input').forEach(el => el.addEventListener('change', updateMenuCheck))
}

// PeriodSelector - handles custom period selection UI
const initPeriodSelector = () => {
  const btnGroup = document.getElementById('timeSelectionBtnGroup')
  if (!btnGroup) return

  const customBtn = document.getElementById('periodSelectCustom')
  const customForm = document.getElementById('timeSelectionCustom')
  const updateBtn = document.getElementById('updatePeriodSelectCustom')
  if (!customBtn || !customForm) return

  customBtn.addEventListener('click', () => {
    customForm.classList.toggle('show')
    customForm.classList.toggle('in')
    btnGroup.classList.toggle('custom-period-selected')
  })

  if (updateBtn) {
    updateBtn.addEventListener('click', (e) => {
      e.preventDefault()
      const startTime = document.getElementById('start_time_selector')?.value
      const endTime = document.getElementById('end_time_selector')?.value
      if (startTime && endTime) {
        const url = new URL(window.location.href)
        url.searchParams.set('start_time', startTime)
        url.searchParams.set('end_time', endTime)
        url.searchParams.set('period', 'custom')
        window.location.href = url.toString()
      }
    })
  }

  // Pagination per_page select
  const perPageSelect = document.getElementById('per_page_select')
  if (perPageSelect) {
    perPageSelect.addEventListener('change', () => {
      const url = new URL(window.location.href)
      url.searchParams.set('per_page', perPageSelect.value)
      window.location.href = url.toString()
    })
  }
}

function localizeTime () {
  if (!window.timeLocalizer) window.timeLocalizer = new TimeLocalizer()
  window.timeLocalizer.localize()
}

document.addEventListener('DOMContentLoaded', localizeTime)
document.addEventListener('turbo:load', () => {
  localizeTime()
  scrollToStoredLocation()
  initPeriodSelector()

  if (document.getElementById('rating-menu')) {
    BrowserExtensionScript()
  }

  enableToggleChecks()
  enableFullscreenTableOverflow()
  setMaxWidths()

  // When JS is enabled, some things should be hidden and some things should be shown
  document.querySelectorAll('.hiddenNoJs').forEach(el => el.classList.remove('hiddenNoJs'))
  document.querySelectorAll('.hiddenOnJs').forEach(el => el.classList.add('hidden'))

  document.querySelectorAll('.expandSiblingsEllipse')
    .forEach(el => el.addEventListener('click', expandSiblingsEllipse))
})
document.addEventListener('turbo:render', localizeTime)
document.addEventListener('turbo:frame-render', localizeTime)
