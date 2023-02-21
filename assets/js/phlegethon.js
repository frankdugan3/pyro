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
      if (this.el.dataset.autoshow !== undefined) {
        window.liveSocket.execJS(
          this.el,
          this.el.getAttribute('data-show-exec-js'),
        )
      }
      resetHideTTL(this)
    },
    updated() {
      if (
        document.querySelector(`#${this.el.id}-message`).innerHTML !==
        this.oldMessageHTML
      ) {
        this.oldEl = this.el
        resetHideTTL(this)
      }
    },
    destroyed() {
      clearInterval(this.ttlInterval)
    },
  },
}

function resetHideTTL(self) {
  clearInterval(self.ttlInterval)
  if (self.el.dataset.ttl > 0) {
    self.countdown = self.el.dataset.ttl
    self.ttlInterval = setInterval(() => {
      self.countdown = self.countdown - 16.7
      if (self.countdown <= 0) {
        window.liveSocket.execJS(
          self.el,
          self.el.getAttribute('data-hide-exec-js'),
        )
      } else {
        el = document.querySelector(`#${self.el.id}>progress`)
        if (el) {
          el.value = self.countdown
        } else {
          clearInterval(self.ttlInterval)
        }
      }
    }, 16.7)
  }
}
