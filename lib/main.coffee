comparitors = require './comparitors'
{EventEmitter} = require 'events'
{getType, hasKeys, removeAt} = require 'torch'
_ = require 'lodash'
logger = require 'ale'

# private API
cache = {}

includes = (rel, search) ->
  for k, v of search
    return false unless rel[k]?
    return false unless _.isEqual rel[k], v
  return true

# used by 'unset' and 'remove'
cleanup = (key, value) ->
  if cache[key][value].length is 0
    delete cache[key][value]
    if _.keys(cache[key]).length is 0
      delete cache[key]

# used by 'add'
add = (stale, fresh) ->
  for k, v of fresh

    # make the input into a set
    if getType(v) is 'Array'
      v = _.uniq v
    else
      v = [v]

    # store new set or union
    switch getType(stale[k])
      when 'Array'
        stale[k] = _.union stale[k], v
      when 'Undefined', 'Null'
        stale[k] = v

# used by 'remove', 'unset'
remover = (relations, key, list) ->
  target = relations[key]
  target = [target] unless _.isArray target
  target = _.without target, list...
  if _.isEmpty target
    delete relations[key]
  else
    relations[key] = target

# public API
class Cache extends EventEmitter
  import: (data) ->
    _.merge cache, data

  clear: ->
    cache = {}

  get: (key, value) ->
    cache?[key]?[value] or {}

  find: (key, comparitor, target) ->
    #logger.magenta {key, comparitor, target}
    return [] unless cache?[key] and comparitors[comparitor]

    results = []
    for value, relations of cache[key]
      try
        if comparitors[comparitor] value, target
          results.push relations

    return results

  # used by 'set' and 'add'
  _inject: (key, value, relation, setter) ->
    return unless key? and value? and _.isObject relation

    run = (key, value, relation, setter) =>
      cache[key] ?= {}
      cache[key][value] ?= {}
      setter cache[key][value], relation
      @emit 'set', {key, value, relation: cache[key][value]}

    # set direct relationships
    run key, value, relation, setter

    # set reverse relationships
    reverseRel = {}
    reverseRel[key] = value
    for k, v of relation
      run k, v, reverseRel, add # always run reverse relations with add

  set: (key, value, relation) ->
    @_inject key, value, relation, _.merge

  add: (key, value, relation) ->
    @_inject key, value, relation, add

  unset: (key, value, targets) ->

    # reformat alternate input types for targets
    switch getType(targets)
      when 'Array'
        targets
      when 'Undefined', 'Null'
        targets = []
      else
        targets = [targets]

    unsetter = (key, value, targets) =>
      @emit 'unset', {key, value, targets}
      for t in targets
        delete cache[key][value][t]
      cleanup key, value

    relations = @get key, value
    if relations?

      if _.isEmpty targets
        targets = _.keys relations

      # walk through and remove all reverse relations
      for t in targets
        revrel = @get t, relations[t]
        @emit 'unset', {key: t, value: relations[t], target: key, list: [value]}
        remover revrel, key, [value]

      # unset direct relation
      unsetter key, value, targets

  remove: (key, value, targets) ->
    return @unset key, value if _.isEmpty targets

    relations = @get key, value
    if relations?

      for tkey, tlist of targets
        tlist = [tlist] unless _.isArray tlist

        for titem in tlist

          # remove reverse lookups
          trel = @get tkey, titem
          if trel?
            @emit 'unset', {key: tkey, value: titem, target: key, list: [value]}
            remover trel, key, [value]

        # remove direct lookups
        @emit 'unset', {key, value, target: tkey, list: tlist}
        remover relations, tkey, tlist

module.exports = new Cache
