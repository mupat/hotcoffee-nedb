hotcoffee = require('hotcoffee')()
nedb = require "#{__dirname}/index"

hotcoffee
  .use(nedb, file: "hotcoffee.db")

hotcoffee.plugins['nedb'].on 'info', (args...) ->
  console.log args...

hotcoffee.plugins['nedb'].on 'error', (err) ->
  console.log 'err', err


hotcoffee.start()
