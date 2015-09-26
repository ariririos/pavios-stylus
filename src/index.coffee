'use strict'

taskName = 'Stylus' # used with humans
safeTaskName = 'stylus' # used with machines

stylus = require 'gulp-stylus'
minify = require 'gulp-minify-css'

{getConfig, gulp, API: {notify, merge, $, reload, handleError, typeCheck, debug}} = require 'pavios'
debug = debug 'task:' + taskName

config = getConfig safeTaskName

defaultOpts =
  minify: no
  sourcemaps: yes
  renameTo: null
  insert: null
  compilerOpts: {}

for srcDestPair in config
  srcDestPair.opts = Object.assign {}, defaultOpts, srcDestPair.opts

# debug 'Merged config: ', config

result = typeCheck.standard config, taskName, typeCheck.types.standardOpts
debug 'Type check ' + (if result then 'passed' else 'failed')

gulp.task safeTaskName, (cb) ->
  unless result
    debug 'Exiting task early because config is invalid'
    return cb()

  streams = []

  for {src, dest, opts} in config
    if src.length > 0 and dest.length > 0
      debug "Creating stream for src #{src} and dest #{dest}..."
      streams.push(
        gulp.src src
        .pipe do handleError taskName
        .pipe $.changed(dest, extension: '.css')
        .pipe $.if(opts.sourcemaps is yes, $.sourcemaps.init())
        .pipe $.if(typeCheck.raw(typeCheck.types.insert, opts.insert), $.insert(opts.insert))
        .pipe stylus opts.compilerOpts
        .pipe $.if(opts.minify is yes, minify())
        .pipe $.if(typeCheck.raw(typeCheck.types.renameTo, opts.renameTo), $.rename(opts.renameTo))
        .pipe $.if(opts.sourcemaps is yes, $.sourcemaps.write())
        .pipe gulp.dest dest
        .pipe reload match: '**/*.css'
        .on 'end', -> notify.taskFinished taskName
      )

  merge streams

module.exports.order = 1
module.exports.sources = (src for {src} in config)
