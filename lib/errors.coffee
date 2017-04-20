module.exports =
class OperationAbortedError extends Error
  constructor: ({@message}) ->
    @name = @constructor.name
