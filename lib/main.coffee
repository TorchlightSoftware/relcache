{EventEmitter} = require 'events'
{getType, box, kvp} = require 'torch'
_ = require 'lodash'
logger = require 'ale'

comparitors = require './comparitors'

# private API
cache = {}

# public API
class Cache extends EventEmitter

  # ================================================================
  # UTILITY
  # ================================================================

  import: (data) ->
    _.merge cache, data

  clear: ->
    cache = {}

  # ================================================================
  # QUERY
  # ================================================================

  get: (key, value, names) ->
    rels = cache[key]?[value] or {}
    unless _.isEmpty names
      names = box names
      return _.pick rels, names...
    else
      return rels

  find: (key, comparitor, target) ->
    return [] unless cache[key] and comparitors[comparitor]

    results = []
    for value, relations of cache[key]
      try
        if comparitors[comparitor] value, target
          results.push relations

    return results

  # ================================================================
  # ADDITION
  # ================================================================

  set: (key, value, relation) ->

    # find the values we're overriding and unset them
    existing = @get key, value
    old = _.intersection _.keys(existing), _.keys(relation)
    @unset key, value, old unless _.isEmpty old

    @_adder key, value, relation, _.merge

    for k, v of relation
      @_adder k, v, kvp(key, value), @_add

  add: (key, value, relation) ->
    @_adder key, value, relation, @_add

    for k, v of relation
      @_adder k, v, kvp(key, value), @_add

  _add: _.partialRight _.merge, (l, r) ->
    _.union box(l), box(r)

  _adder: (key, value, relation, method) ->
    cache[key] ?= {}
    cache[key][value] ?= {}

    method cache[key][value], relation
    @emit 'add', {key, value, relation}

  # ================================================================
  # REMOVAL
  # ================================================================

  unset: (key, value, targets) ->
    # turn args into appropriate values for helpers
    if targets
      targets = box targets
      tObj = @_toObjKeys(targets)

    rels = @get key, value, targets
    for k, v of rels
      @_remover k, v, kvp(key, value), @_remove

    @_remover key, value, tObj, @_unset

  remove: (key, value, targets) ->
    rels = @get key, value, _.keys(targets)
    for k, v of rels
      @_remover k, v, kvp(key, value), @_remove

    @_remover key, value, targets, @_remove

  _toObjKeys: (list) ->
    if _.isArray list
      _.object _.zip list
    else
      list

  _unset: (relation, targets) ->
    for k of targets
      delete relation[k]

  _remove: (relation, targets) ->
    for tkey, tlist of targets
      tlist = box tlist
      if relation[tkey]
        relation[tkey] = _.without relation[tkey], tlist...
        delete relation[tkey] if _.isEmpty relation[tkey]

  _remover: (key, value, targets, method) ->
    relation = cache[key]?[value]
    targets ?= relation

    if relation?
      @emit 'remove', {key, value, targets}
      method relation, targets

      if _.isEmpty relation
        delete cache[key][value]
        if _.isEmpty cache[key]
          delete cache[key]

module.exports = new Cache
