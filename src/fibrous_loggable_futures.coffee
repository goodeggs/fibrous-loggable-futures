_ = require 'underscore'

module.exports = (fibrous, logger) ->
  Future = fibrous.Future

  # various signatures that andLogResults handles:
  # andLogResults('foo')
  # andLogResults('foo', errorsOnly: true)
  # andLogResults({more: 'context'}, 'foo', errorsOnly: true)
  # andLogResults({more: 'context', msg: 'foo'}, errorsOnly: true)
  andLogResults = (contextObj, contextMsg, options) ->
    if _(contextObj).isString()
      [contextMsg, contextObj, options] = [contextObj, {}, contextMsg]
    if _(contextMsg).isObject()
      [contextMsg, options] = [contextObj.msg, contextMsg]
    options ?= {}
    throw new Error('You must supply a contextMsg to andLogResults') if !contextMsg
    @resolve (err, result) ->
      if err?
        logger.error _({err}).extend(contextObj), "\"#{contextMsg}\"", 'error from Future#andLogResults'
      else if !options.errorsOnly
        # Ignore the result parameter since the return on most fibrous functions may simply be noise
        logger.info contextMsg, 'success'
    @

  Future::andLogResults = andLogResults

  # Keep track of all logged futures so that we can wait for them, eg in tasks or tests
  pendingLoggedFutures = null
  capturingAndLogResults = (args...) ->
    pendingLoggedFutures.push(@)
    andLogResults.apply(@, args)

  fibrous.captureLoggedFutures = ->
    if pendingLoggedFutures
      throw new Error 'already capturing logged futures'
    pendingLoggedFutures = []
    Future::andLogResults = capturingAndLogResults unless Future::andLogResults is capturingAndLogResults

  fibrous.uncaptureLoggedFutures = ->
    pendingLoggedFutures = null
    Future::andLogResults = andLogResults

  fibrous.waitForLoggedFutures = fibrous ->
    unless pendingLoggedFutures
      throw new Error 'not capturing logged futures'
    err = null
    # ensure we get through all the futures, including those created as a result of one of the futures, even if there is an error
    while future = pendingLoggedFutures.shift()
      try
        fibrous.wait(future)
      catch e
        err ?= e
    # Throw the first err if it exists
    throw err if err?


