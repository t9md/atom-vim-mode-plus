module.exports = class OperationAbortedError extends Error {
  constructor({message}) {
    super()
    this.message = message
    this.name = this.constructor.name
  }
}
