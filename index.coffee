EventEmitter = require('events').EventEmitter

class Plugin extends EventEmitter
  constructor: (@app, @opts={}) ->
    @name = 'nedb'
    @db = @opts.client || new (require('nedb')) @opts.file
    @db.loadDatabase @loadDatabase.bind(@)

  loadDatabase: (err) ->
    return @emit 'error', err if err?

    @registerEvents()
    @db.find {}, (err, docs) =>
      return @emit 'error', err if err?
      @loadDocuments doc for doc in docs

  loadDocuments: (document)->
    @app.db[document.resource] = [] unless @app.db[document.resource]?
    @app.db[document.resource].push document

  registerEvents: ->
    @app.on 'POST', (resource, data) =>
      data.resource = resource

      @db.insert data, (err, docs) =>
        return @emit 'error', err if err?
        @emit 'info', "new document inserted", docs

    @app.on 'DELETE', (resource, items) =>
      ids = items.map (x) -> x._id
      @db.remove '_id': { $in:ids }, { multi: true }, (err, count) =>
        return @emit 'error', err if err?
        @emit 'info', "#{count} documents removed"

    @app.on 'PATCH', (resource, items, data) =>
      ids = items.map (x)-> x._id
      @db.update '_id': { $in:ids }, { $set: data }, { multi: true }, (err, count) =>
        return @emit 'error', err if err?
        @emit 'info', "#{count} documents updated"

module.exports = (app, opts)->
  return new Plugin app, opts
