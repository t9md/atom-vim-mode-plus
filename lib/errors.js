module.exports = class OperationAbortedError extends Error {
  constructor({message}) {
    this.message = message
    this.name = this.constructor.name
  }
}
