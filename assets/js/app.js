// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

let hooks = {}
hooks.AreaChart = {
  mounted() {
    let ctx = this.el.getContext('2d');
    let chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: [],
        datasets: [{
          label: 'Humidity',
          backgroundColor: 'rgb(37, 120, 244, 0.5)',
          borderColor: 'rgb(37, 120, 244)',
          data: [],
        },
        {
          label: 'Temp',
          backgroundColor: 'rgba(255, 99, 132, 0.5)',
          borderColor: 'rgb(255, 99, 132)',
          data: [],
        }]
      },

      options: {
        responsive: true,
        hoverMode: 'index',
        stacked: false
      }
    });

    this.handleEvent("data-updated", (payload) => {
      if(chart.data.datasets[0].data.length >= 10) {
        chart.data.datasets[0].data.shift()
        chart.data.datasets[0].data.push(payload.rh)

        chart.data.datasets[1].data.shift()
        chart.data.datasets[1].data.push(payload.temp)

        chart.data.labels.shift()
        chart.data.labels.push(payload.timestamp)
      } else {
        chart.data.datasets[0].data.push(payload.rh)
        chart.data.datasets[1].data.push(payload.temp)
        chart.data.labels.push(payload.timestamp)
      }

      chart.update()
    })
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
