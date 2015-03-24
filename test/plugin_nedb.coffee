should = require 'should'
sinon = require 'sinon'
EventEmitter = require('events').EventEmitter
Plugin = require "#{__dirname}/../index"

describe 'plugin nedb', ->
  beforeEach ->
    @app = new EventEmitter()
    @app.db = {}
    @turtles = [
      { id: 1, _id: 1, name: 'Donatello', resource: 'turtles' }
      { id: 2, _id: 2, name: 'Leonardo', resource: 'turtles' }
      { id: 3, _id: 3, name: 'Michelangelo', resource: 'turtles2' }
      { id: 4, _id: 4, name: 'Raphael', resource: 'turtles2' }
    ]

    @client =
      loadDatabase: sinon.stub()
      insert: sinon.stub()
      remove: sinon.stub()
      update: sinon.stub()
      find: sinon.stub()

    @client.loadDatabase.callsArgWith 0, null
    @client.find.callsArgWith 1, null, @turtles
    @client.insert.callsArgWith 1, null, {}
    @client.update.callsArgWith 3, null, @turtles.length
    @client.remove.callsArgWith 2, null, @turtles.length

  it 'should provide the correct name', ->
    @plugin = Plugin @app, {client: @client}
    @plugin.name.should.equal 'nedb'

  describe 'loadDatabase', ->
    it 'should load the database', ->
      @plugin = Plugin @app, {client: @client}

      @client.loadDatabase.calledOnce.should.be.true
      @client.find.calledOnce.should.be.true

    it 'should throw the load database error', ->
      @client.loadDatabase.callsArgWith 0, new Error('error')

      try
        @plugin = Plugin @app, {client: @client}
      catch error
        error.message.should.equal 'error'

  describe 'loadDocuments', ->
    it 'should add the documents to the app db', ->
      @plugin = Plugin @app, {client: @client}

      Object.keys(@app.db).should.eql ['turtles', 'turtles2']

    it 'should throw the find error', ->
      @client.find.callsArgWith 1, new Error('error')

      try
        @plugin = Plugin @app, {client: @client}
      catch error
        error.message.should.equal 'error'

  describe 'registerEvents', ->
    it 'should react on POST events', (done) ->
      resource = 'beatles'
      data = name: 'John Lennon'

      @plugin = Plugin @app, {client: @client}
      @plugin.on 'info', (text) =>
        text.should.equal "new document inserted"
        data.resource = resource
        @client.insert.calledWith(data).should.be.true
        done()

      @app.emit 'POST', resource, data

    it 'should emit the POST insert error', (done) ->
      @client.insert.callsArgWith 1, new Error('error')

      @plugin = Plugin @app, {client: @client}
      @plugin.on 'error', (error) =>
        error.message.should.equal "error"
        done()

      @app.emit 'POST', '', {}

    it 'should react on PATCH events', (done) ->
      resource = 'turtles'
      items = @turtles
      data = status: 'hungry'

      @plugin = Plugin @app, {client: @client}
      @plugin.on 'info', (text) =>
        text.should.equal "#{@turtles.length} documents updated"
        @client.update.calledOnce.should.be.true
        done()

      @app.emit 'PATCH', resource, items, data

    it 'should emit the PATCH insert error', (done) ->
      @client.update.callsArgWith 3, new Error('error')

      @plugin = Plugin @app, {client: @client}
      @plugin.on 'error', (error) =>
        error.message.should.equal "error"
        done()

      @app.emit 'PATCH', '', [], {}

    it 'should react on DELETE events', (done) ->
      resource = 'turtles'
      items = @turtles

      @plugin = Plugin @app, {client: @client}
      @plugin.on 'info', (text) =>
        text.should.equal "#{@turtles.length} documents removed"
        @client.remove.calledOnce.should.be.true
        done()

      @app.emit 'DELETE', resource, items

    it 'should emit the DELETE insert error', (done) ->
      @client.remove.callsArgWith 2, new Error('error')

      @plugin = Plugin @app, {client: @client}
      @plugin.on 'error', (error) =>
        error.message.should.equal "error"
        done()

      @app.emit 'DELETE', '', []
