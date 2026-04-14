import { Controller } from '@hotwired/stimulus'

/* global localStorage */
// Connects to data-controller="theme"
export default class extends Controller {
  static targets = ['option']
  static values = { url: String, current: String }

  connect () {
    // Don't override Lookbook's display theme setting on connect
    if (window.inComponentPreview) return
    if (!this.currentValue) return
    this.applyTheme(this.currentValue)
    this.highlightActive()
  }

  select (event) {
    event.preventDefault()
    const theme = event.currentTarget.dataset.theme
    this.currentValue = theme
    this.applyTheme(theme)
    this.highlightActive()
    this.save(theme)
  }

  applyTheme (theme) {
    const html = document.documentElement
    if (theme === 'theme_dark') {
      html.classList.add('dark')
      localStorage.setItem('theme', 'dark')
    } else if (theme === 'theme_light') {
      html.classList.remove('dark')
      localStorage.setItem('theme', 'light')
    } else {
      // system
      localStorage.removeItem('theme')
      if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
        html.classList.add('dark')
      } else {
        html.classList.remove('dark')
      }
    }
  }

  highlightActive () {
    this.optionTargets.forEach(el => {
      const isActive = el.dataset.theme === this.currentValue
      el.classList.toggle('ring-2', isActive)
      el.classList.toggle('ring-blue-500', isActive)
      el.classList.toggle('opacity-60', !isActive)
      el.classList.toggle('opacity-100', isActive)
    })
  }

  setSignupCookies () {
    const theme = localStorage.getItem('theme')
    if (theme) {
      document.cookie = `signup_theme=${theme};path=/;max-age=300;SameSite=Lax`
    }
  }

  save (theme) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': token,
        Accept: 'text/html'
      },
      body: JSON.stringify({ user: { theme } })
    })
  }
}
