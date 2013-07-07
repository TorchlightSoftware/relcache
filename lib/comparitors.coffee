_ = require 'lodash'
logger = require 'ale'

module.exports =

  eq: (left, right) ->
    left is right.toString()

  ne: (left, right) ->
    left isnt right.toString()

  gte: (left, right) ->
    left >= right

  gt: (left, right) ->
    left > right

  lte: (left, right) ->
    left <= right

  lt: (left, right) ->
    left < right

  all: (left, right) ->
    arr = left.split(',')
    for value in right
      return false unless _.contains arr, value
    return true

  in: (left, right) ->
    left in right

  nin: (left, right) ->
    left not in right

