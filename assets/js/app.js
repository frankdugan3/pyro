import { hooks, getTimezone } from './pyro'
import 'phoenix_html'
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'
// import topbar from '../vendor/topbar'

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content')
let liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken, timezone: getTimezone() },
  hooks: { ...hooks },
})

// Show progress bar on live navigation and form submits
// topbar.config({
//   barThickness: 10,
//   barColors: {
//     0: '#2C5282',
//     '.25': '#2B6CB0',
//     '.5': '#3182CE',
//     '.75': '#4299E1',
//     '1.0': '#63B3ED',
//   },
// })
// window.addEventListener('phx:page-loading-start', (info) => topbar.show())
// window.addEventListener('phx:page-loading-stop', (info) => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
