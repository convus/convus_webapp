# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/utils", under: "utils"
pin "@bikeindex/time-localizer", to: "https://cdn.jsdelivr.net/npm/@bikeindex/time-localizer@0.1.1/index.js"
pin "@floating-ui/dom", to: "https://cdn.jsdelivr.net/npm/@floating-ui/dom@1.7.3/+esm"
pin "sortablejs", to: "https://cdn.jsdelivr.net/npm/sortablejs@1.15.6/modular/sortable.esm.js"
pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"
