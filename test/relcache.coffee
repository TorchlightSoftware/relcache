should = require 'should'
relcache = require '..'

describe 'Relations Cache', ->
  beforeEach ->
    relcache.clear()

  it 'with no data should return empty array', (done) ->
    rels = relcache.get 'sessionId', 123
    rels.should.exist
    rels.should.be.an.instanceof Array
    rels.should.be.empty
    done()

  it 'should store and retrieve relation', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456}
    rels = relcache.get 'sessionId', 123

    rels.should.exist
    rels.should.eql [{accountId: 456}]
    done()

  it 'should store and retrieve reverse relation', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456}
    rels = relcache.get 'accountId', 456

    rels.should.exist
    rels.should.eql [{sessionId: 123}]
    done()

  it 'should store and retrieve duplicate keys', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456}
    relcache.set 'sessionId', 123, {accountId: 789}

    rels = relcache.get 'sessionId', 123

    rels.should.exist
    rels.should.eql [{accountId: 456}, {accountId: 789}]
    done()

  it 'should import data', (done) ->
    relcache.import {
      sessionId:
        '123': [
          {accountId: 456}
        ]
    }

    rels = relcache.get 'sessionId', 123

    rels.should.exist
    rels.should.eql [{accountId: 456}]
    done()

  it 'should unset all relations', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456}
    relcache.set 'sessionId', 123, {accountId: 789}
    relcache.unset 'sessionId', 123
    rels = relcache.get 'sessionId', 123

    rels.should.exist
    rels.should.be.an.instanceof Array
    rels.should.be.empty
    done()

  it 'should unset all reverse relations', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456}
    relcache.set 'sessionId', 123, {accountId: 789}
    relcache.unset 'sessionId', 123

    r1 = relcache.get 'accountId', 456
    r2 = relcache.get 'accountId', 456

    for r in [r1, r2]
      r.should.exist
      r.should.be.an.instanceof Array
      r.should.be.empty
    done()

  it 'should unset target relation', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456}
    relcache.set 'sessionId', 123, {accountId: 789}
    relcache.unset 'sessionId', 123, {accountId: 456}
    rels = relcache.get 'sessionId', 123

    rels.should.exist
    rels.should.eql [{accountId: 789}]
    done()

  it 'should unset reverse relations', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456}
    relcache.set 'sessionId', 123, {accountId: 789}
    relcache.unset 'sessionId', 123, {accountId: 456}
    rels = relcache.get 'accountId', 456

    rels.should.exist
    rels.should.eql []
    done()

  it 'should find a key', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456}
    relcache.set 'sessionId', 123, {accountId: 789}
    rel = relcache.findOne 'sessionId', 123, {accountId: 456}

    rel.should.exist
    rel.should.eql {accountId: 456}
    done()

  it 'should find the first relation', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456}
    rel = relcache.findOne 'sessionId', 123

    rel.should.exist
    rel.should.eql {accountId: 456}
    done()

  it 'should find an index', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456}
    relcache.set 'sessionId', 123, {accountId: 789}
    index = relcache.findIndex 'sessionId', 123, {accountId: 456}

    index.should.exist
    index.should.eql 0
    done()

  it 'should emit a set event', (done) ->
    relcache.once 'set', ({key, value, relation}) ->
      key.should.eql 'sessionId'
      value.should.eql 123
      relation.should.eql {accountId: 456}

      done()

    relcache.set 'sessionId', 123, {accountId: 456}

  it 'should emit an unset event', (done) ->
    relcache.once 'unset', ({key, value, relation}) ->
      key.should.eql 'sessionId'
      value.should.eql 123
      should.not.exist relation

      done()

    relcache.set 'sessionId', 123, {accountId: 456}
    relcache.unset 'sessionId', 123
