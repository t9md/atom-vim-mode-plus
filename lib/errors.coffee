class VimModePlusError extends Error
  constructor: ({@message}) ->
    @name = @constructor.name

class OperationStackError extends VimModePlusError

class OperatorError extends VimModePlusError

class OperationAbortedError extends VimModePlusError

module.exports = {
  OperationStackError
  OperatorError
  OperationAbortedError
}
