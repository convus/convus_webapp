module.exports = function (api) {
  const validEnv = ['development', 'test', 'production']
  const currentEnv = api.env()

  if (!validEnv.includes(currentEnv)) {
    throw new Error(
      'Please specify a valid `NODE_ENV` or ' +
        '`BABEL_ENV` environment variables. Valid values are "development", ' +
        '"test", and "production". Instead, received: ' +
        JSON.stringify(currentEnv) +
        '.'
    )
  }

  return {
    presets: [
      [
        '@babel/preset-env',
        {
          forceAllTransforms: true,
          useBuiltIns: 'usage',
          corejs: 3,
          modules: 'commonjs',
          exclude: ['transform-typeof-symbol'],
          targets: {
            node: 'current',
            browsers: '> 1%'
          }
        }
      ]
    ].filter(Boolean)
  }
}
