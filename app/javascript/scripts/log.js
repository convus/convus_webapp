import loglevel from 'loglevel'

if (process.env.RAILS_ENV === 'production') {
  // It should be this by default - but that isn't happening, so setting it manually
  loglevel.setLevel('warn')
} else {
  loglevel.setLevel('debug')
}

export default loglevel
