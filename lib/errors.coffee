class VimModePlusError extends Error
  constructor: ({@message}) ->
    @name = @constructor.name

class OperationAbortedError extends VimModePlusError

module.exports = {
  OperationAbortedError
}
