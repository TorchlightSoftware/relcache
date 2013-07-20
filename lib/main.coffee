{EventEmitter} = require 'events'
{getType, box, kvp} = require 'torch'
_ = require 'lodash'
logger = require 'ale'

comparitors = require './comparitors'

class Cache extends EventEmitter

  _cache: {}

  # ================================================================
  # UTILITY
  # ================================================================

  import: (data) ->
    _.merge @_cache, data

  clear: ->
    @_cache = {}

  # ================================================================
  # QUERY
  # ================================================================

  get: (key, value, names) ->
    if value is undefined and names is undefined
      return _.keys @_cache[key]

    rels = @_cache[key]?[value] or {}
    if _.isArray names
      names = box names
      return _.pick rels, names...
    else if names?
      return rels[names]
    else
      return rels

  find: (key, comparitor, target) ->
    return [] unless @_cache[key] and comparitors[comparitor]

    results = {}
    for value, relations of @_cache[key]
      try
        if comparitors[comparitor] value, target
          @_add results, relations

    return results

  follow: (key, keypath) ->
    parts = keypath.split '>'
    return {} unless parts.length >= 2

    dig = (key, parts...) =>
      [first, second, rest...] = parts
      return key unless first? and second?

      relations = @find first, 'in', box(key)
      target = relations[second]
      return target if _.isEmpty target
      return dig target, second, rest...

    dig key, parts...

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
    @_cache[key] ?= {}
    @_cache[key][value] ?= {}

    method @_cache[key][value], relation
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
    relation = @_cache[key]?[value]
    targets ?= relation

    if relation?
      @emit 'remove', {key, value, targets}
      method relation, targets

      if _.isEmpty relation
        delete @_cache[key][value]
        if _.isEmpty @_cache[key]
          delete @_cache[key]

module.exports = Cache
