// This has some of the JS that is included in the browser extension, to make testing easier
// I expect to put more of it in here eventually

import log from './log' // eslint-disable-line

const BrowserExtensionScript = () => {
  const toggleTopicsVisible = (isVisible) => {
    window.topicsVisibile = isVisible
    if (window.topicsVisibile) {
      document.getElementById('field-group-topics').classList.remove('hidden')
    } else {
      document.getElementById('field-group-topics').classList.add('hidden')
    }
    // browser.storage.local.set({topicsVisible: isVisible})
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

export default BrowserExtensionScript
