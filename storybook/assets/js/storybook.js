import { hooks, getTimezone } from 'pyro'
let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content')

;(function () {
  window.storybook = {
    Hooks: hooks,
    Params: { _csrf_token: csrfToken, timezone: getTimezone() },
  }
})()
