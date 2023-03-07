const path = require('path')
const fs = require('fs')

const watch = process.argv.includes('--watch')
const errorFilePath = 'esbuild_error'

// TODO: Figure out why this isn't assigned automatically
process.env.RAILS_ENV ||= 'development'

const watchOptions = {
  onRebuild (error, result) {
    if (error) {
      console.error('watch build failed:', error)
      fs.writeFileSync(errorFilePath, error.toString())
    } else if (fs.existsSync(errorFilePath)) {
      console.log('watch build succeeded:', result)
      fs.truncate(errorFilePath, 0, () => {})
    }
  }
}

require('esbuild')
  .build({
    define: {
      'process.env.RAILS_ENV': `"${process.env.RAILS_ENV}"`
    },
    entryPoints: ['application.js'],
    bundle: true,
    sourcemap: true,
    outdir: path.join(process.cwd(), 'app/assets/builds'),
    absWorkingDir: path.join(process.cwd(), 'app/javascript'),
    watch: watch && watchOptions,
    // custom plugins will be inserted is this array
    plugins: []
  })
  .then((result) => console.log('esbuild is watching for changes:', result))
