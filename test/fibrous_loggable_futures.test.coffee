require 'mocha-sinon'
chai = require 'chai'
chai.use require 'sinon-chai'
expect = chai.expect
fibrous = require 'fibrous'
loggableFutures = require '../src/fibrous_loggable_futures'

describe 'fibrous-loggable-futures', ->
  before ->
    @logger =
      error: ->
      info: ->
    loggableFutures fibrous, @logger

  beforeEach ->
    @sinon.stub @logger

  describe 'Future::andLogResults', ->
    {obj, err} = {}

    beforeEach ->
      fibrous.captureLoggedFutures()
    afterEach ->
      fibrous.uncaptureLoggedFutures()

    describe 'with an error', ->
      beforeEach ->
        err = new Error('boom')
        obj =
          asyncF: (cb) ->
            process.nextTick ->
              cb(err)

      it 'logs the error along with a context', ->
        obj.future.asyncF().andLogResults({contextKey: 'contextValue'}, 'some message')
        expect(-> fibrous.sync.waitForLoggedFutures()).to.throw('boom')
        expect(@logger.error).to.have.been.calledWith({err, contextKey: 'contextValue'}, '"some message"', 'error from Future#andLogResults')

      it 'handles a null context', ->
        obj.future.asyncF().andLogResults(null, 'some message')
        expect(-> fibrous.sync.waitForLoggedFutures()).to.throw('boom')
        expect(@logger.error).to.have.been.calledWith({err}, '"some message"', 'error from Future#andLogResults')

      describe 'with a custom logger', ->
        it 'logs the error with the custom logger', ->
          customLogger = error: @sinon.spy()
          obj.future.asyncF().andLogResults({contextKey: 'contextValue'}, 'some message', {logger: customLogger})
          expect(-> fibrous.sync.waitForLoggedFutures()).to.throw('boom')
          expect(@logger.error).not.to.have.been.called
          expect(customLogger.error).to.have.been.calledWith({err, contextKey: 'contextValue'}, '"some message"', 'error from Future#andLogResults')

  describe '.waitForLoggedFutures', ->
    describe 'when not capturing logged futures', ->
      it 'throws', ->
        expect(-> fibrous.sync.waitForLoggedFutures()).to.throw /not capturing/

  describe '.captureLoggedFutures', ->
    it 'throws when already capturing', ->
      fibrous.captureLoggedFutures()
      expect(-> fibrous.captureLoggedFutures()).to.throw /already capturing/
