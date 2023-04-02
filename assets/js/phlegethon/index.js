// #############################################################################
// ####    T H E M E    M A N A G E M E N T
// #############################################################################

// Load user or system preference for dark or light theme
if (
  localStorage.theme === 'dark' ||
  (!('theme' in localStorage) &&
    window.matchMedia('(prefers-color-scheme: dark)').matches)
) {
  document.documentElement.classList.add('dark')
} else {
  document.documentElement.classList.remove('dark')
}

// Set theme to dark
window.addEventListener('phlegethon:theme-dark', (e) => {
  localStorage.theme = 'dark'
  document.documentElement.classList.add('dark')
})

// Set theme to light
window.addEventListener('phlegethon:theme-light', (e) => {
  localStorage.theme = 'light'
  document.documentElement.classList.remove('dark')
})

// Set theme to system preference
window.addEventListener('phlegethon:theme-system', (e) => {
  localStorage.removeItem('theme')
  if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
    document.documentElement.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
  }
  document.documentElement.classList.add('dark')
})

// #############################################################################
// ####    C U S T O M    E V E N T    H A N D L E R S
// #############################################################################

window.addEventListener('phlegethon:clear', (e) => {
  if (e?.target?.value != '') {
    e.target.value = ''
  }
})

// #############################################################################
// ####    T I M E Z O N E    T O O L I N G
// #############################################################################
export function getTimezone() {
  return Intl.DateTimeFormat().resolvedOptions().timeZone
}

export async function sendTimezoneToServer() {
  const timezone = getTimezone()
  let csrfToken = document
    .querySelector("meta[name='csrf-token']")
    .getAttribute('content')

  // Skip if we sent the timezone already or the timezone changed since last time we sent
  if (
    typeof window.localStorage != 'undefined' &&
    (!localStorage['timezone'] || localStorage['timezone'] != timezone)
  ) {
    const response = await fetch('/session/set-timezone', {
      method: 'POST',
      mode: 'cors',
      cache: 'no-cache',
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        'x-csrf-token': csrfToken,
      },
      referrerPolicy: 'no-referrer',
      body: JSON.stringify({ timezone: timezone }),
    })

    if (response.status === 200) {
      localStorage['timezone'] = timezone
    }
  }
}

// #############################################################################
// ####    H O O K S
// #############################################################################

export const hooks = {
  PhlegethonFlashComponent: {
    mounted() {
      this.oldMessageHTML = document.querySelector(
        `#${this.el.id}-message`,
      ).innerHTML
      if (this.el.dataset?.autoshow !== undefined) {
        window.liveSocket.execJS(
          this.el,
          this.el.getAttribute('data-show-exec-js'),
        )
      }
      resetHideTTL(this)
    },
    updated() {
      newMessageHTML = document.querySelector(
        `#${this.el.id}-message`,
      ).innerHTML
      if (newMessageHTML !== this.oldMessageHTML) {
        this.oldEl = this.el
        this.oldMessageHTML = newMessageHTML
        resetHideTTL(this)
      } else {
        el.value = this.countdown
      }
    },
    destroyed() {
      clearInterval(this.ttlInterval)
    },
  },
  PhlegethonNudgeIntoView: {
    mounted() {
      nudge(this.el)
    },
    updated() {
      nudge(this.el)
    },
  },
  PhlegethonAutocompleteComponent: {
    mounted() {
      this.lastValueSent = null
      const expanded = () => {
        return booleanDataset(this.el.getAttribute('aria-expanded'))
      }

      const updateSearchThrottled = throttle(() => {
        if (this.lastValueSent !== this.el.value || !expanded()) {
          this.lastValueSent = this.el.value
          this.pushEventTo(this.el.dataset.myself, 'search', this.el.value)
        }
      }, this.el.dataset.throttleTime)

      if (this.el.dataset.autofocus) {
        focusAndSelect(this.el)
      }

      const selectedIndex = () => {
        return parseInt(this.el.dataset.selectedIndex)
      }
      const options = () => {
        const listbox = document.getElementById(
          this.el.getAttribute('aria-controls'),
        )

        if (listbox?.children) {
          return Array.from(listbox.children)
        } else {
          return []
        }
      }

      const setSelectedIndex = (selectedIndex) => {
        // Loop selectedIndex back to first or last result if out of bounds
        const rc = parseInt(this.el.dataset.resultsCount)
        selectedIndex = ((selectedIndex % rc) + rc) % rc
        this.el.dataset.selectedIndex = selectedIndex

        options().forEach((option, i) => {
          if (i === selectedIndex) {
            option.setAttribute('aria-selected', true)
          } else {
            option.removeAttribute('aria-selected')
          }
        })
      }

      const pick = (e) => {
        const i = selectedIndex()
        const input_el = document.getElementById(this.el.dataset.inputId)
        let label = ''
        let value = ''

        if (i > -1) {
          const option = options()[i]
          label = option.dataset.label
          value = option.dataset.value
        }

        e.preventDefault()
        e.stopPropagation()
        this.el.value = label
        this.el.focus()
        selectValue(this.el)
        this.pushEventTo(this.el.dataset.myself, 'pick', {
          label,
          value,
        })

        input_el.value = value
        input_el.dispatchEvent(new Event('input', { bubbles: true }))

        return false
      }

      this.el.addEventListener('keydown', (e) => {
        switch (e.key) {
          case 'Tab':
            if (expanded()) {
              return pick(e)
            } else {
              return true
            }
          case 'Esc': // IE/Edge
          case 'Escape':
            if (this.el.value !== '' || !expanded()) {
              e.preventDefault()
              e.stopPropagation()
              this.el.value = ''
              this.el.dataset.selectedIndex = -1
              options().forEach((option, i) => {
                option.removeAttribute('aria-selected')
              })
              updateSearchThrottled()
              return false
            } else if (expanded()) {
              e.preventDefault()
              e.stopPropagation()
              this.el.value = this.el.dataset.savedLabel || ''
              selectValue(this.el)
              this.pushEventTo(this.el.dataset.myself, 'cancel')
              this.lastValueSent = null
              return false
            } else {
              return true
            }
          case 'Enter':
            if (expanded()) {
              return pick(e)
            } else {
              this.el.value = ''
              e.preventDefault()
              e.stopPropagation()
              updateSearchThrottled()
              return false
            }
          case 'Up': // IE/Edge
          case 'Down': // IE/Edge
          case 'ArrowUp':
          case 'ArrowDown':
            if (expanded()) {
              e.preventDefault()
              e.stopPropagation()

              let i = selectedIndex()
              i = e.key === 'ArrowUp' || e.key === 'Up' ? i - 1 : i + 1
              setSelectedIndex(i)

              return false
            } else {
              return true
            }
          default:
            return true
        }
      })
      this.el.addEventListener('focus', (e) => {
        selectValue(this.el)
      })
      this.el.addEventListener('input', (e) => {
        switch (e.inputType) {
          case 'insertText':
          case 'deleteContentBackward':
          case 'deleteContentForward':
            updateSearchThrottled()
            return true
          default:
            return false
        }
      })
      this.el.addEventListener('pick', (e) => {
        setSelectedIndex(e.detail.dispatcher.dataset.index)
        return pick(e)
      })
    },
  },
  PhlegethonCopyToClipboard: {
    mounted() {
      this.content = this.el.innerHTML
      let { value, message, ttl } = this.el.dataset
      this.el.addEventListener('click', (e) => {
        e.preventDefault()
        navigator.clipboard.writeText(value)
        this.el.innerHTML = message || 'Copied to clipboard!'
        this.timeout = window.setTimeout(() => {
          this.el.innerHTML = this.content
        }, ttl)
      })
    },
    updated() {
      window.clearTimeout(this.timeout)
    },
    destroyed() {
      window.clearTimeout(this.timeout)
    },
  },
}

function nudge(el) {
  let width = window.innerWidth
  let height = window.innerHeight
  let rect = el.getBoundingClientRect()

  hOffset = el.dataset?.horizontalOffset || 0
  vOffset = el.dataset?.verticalOffset || 0

  // TODO: The 24 padding is arbitrary -- look into a better way to figure out extra padding.

  // Nudge left if offscreen
  if (rect.right + 24 > width) {
    el.style.right = hOffset
    el.style.left = null
  } else {
    el.style.left = hOffset
    el.style.right = null
  }

  // Nudge up if offscreen
  if (rect.bottom + 24 > height) {
    el.style.bottom = vOffset
    el.style.top = null
  } else {
    el.style.top = vOffset
    el.style.bottom = null
  }
}

function resetHideTTL(self) {
  clearInterval(self.ttlInterval)
  if (self.el.dataset?.ttl > 0) {
    self.countdown = self.el.dataset?.ttl
    self.ttlInterval = setInterval(() => {
      self.countdown = self.countdown - 16.7
      if (self.countdown <= 0) {
        window.liveSocket.execJS(
          self.el,
          self.el.getAttribute('data-hide-exec-js'),
        )
      } else {
        el = document.querySelector(`#${self.el.id}>section>progress`)
        if (el) {
          el.value = self.countdown
        } else {
          clearInterval(self.ttlInterval)
        }
      }
    }, 16.7)
  }
}

export function throttle(callback, limit) {
  let waiting = false
  return function () {
    if (!waiting) {
      callback.apply(this, arguments)
      waiting = true
      setTimeout(function () {
        callback.apply(this, arguments)
        waiting = false
      }, limit)
    }
  }
}

export function selectValue(el) {
  if (typeof el.select === 'function') {
    el.select()
  }
}

export function focusAndSelect(el) {
  el.focus()
  selectValue(el)
}

export function booleanDataset(value) {
  return ![null, undefined, false, 'false'].includes(value)
}
