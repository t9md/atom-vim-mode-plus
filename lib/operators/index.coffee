_ = require 'underscore-plus'
Operators = require './general-operators'
Operators.Put = require './put-operator'
Operators.Replace = require './replace-operator'
_.extend(Operators, (require './input'))
module.exports = Operators
