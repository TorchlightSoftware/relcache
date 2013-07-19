should = require 'should'
logger = require 'ale'

Relcache = require '..'
relcache = new Relcache

describe 'Relations Cache', ->
  beforeEach ->
    relcache.clear()

  it 'with no data should return empty object', (done) ->
    rels = relcache.get 'sessionId', 123
    rels.should.exist
    rels.should.eql {}
    done()

  it 'should store and retrieve relation', (done) ->
    relcache.set 'sessionId', 123, {name: 'Bob'}
    rels = relcache.get 'sessionId', 123

    rels.should.exist
    rels.should.eql {name: 'Bob'}
    done()

  it 'should get specific field', (done) ->
    relcache.set 'sessionId', 123, {name: 'Bob'}
    rels = relcache.get 'sessionId', 123, 'name'

    rels.should.exist
    rels.should.eql 'Bob'
    done()

  it 'should get multiple fields', (done) ->
    relcache.set 'sessionId', 123, {name: 'Bob', email: 'bob@foo.com', loginCount: 5}
    rels = relcache.get 'sessionId', 123, ['name', 'email']

    rels.should.exist
    rels.should.eql {name: 'Bob', email: 'bob@foo.com'}
    done()

  it 'should store and retrieve reverse relation', (done) ->
    relcache.set 'sessionId', 123, {name: 'Bob'}
    rels = relcache.get 'name', 'Bob'

    rels.should.exist
    rels.should.eql {sessionId: [123]}
    done()

  it 'reverse relations should accumulate', (done) ->
    relcache.set 'sessionId', 123, {name: 'Bob'}
    relcache.set 'sessionId', 456, {name: 'Bob'}
    rels = relcache.get 'name', 'Bob'

    rels.should.exist
    rels.should.eql {sessionId: [123, 456]}
    done()

  it 'should store and retrieve one to many relationship', (done) ->
    relcache.add 'accountId', 123, {sessionId: 456}
    relcache.add 'accountId', 123, {sessionId: 789}

    rels = relcache.get 'accountId', 123

    rels.should.exist
    rels.should.eql {sessionId: [456, 789]}
    done()

  it 'should store and retrieve one to many with array', (done) ->
    relcache.add 'accountId', 123, {sessionId: [456, 789]}

    rels = relcache.get 'accountId', 123

    rels.should.exist
    rels.should.eql {sessionId: [456, 789]}
    done()

  it 'should remove one to many relationship', (done) ->
    relcache.add 'accountId', 123, {sessionId: 456}
    relcache.add 'accountId', 123, {sessionId: 789}
    relcache.remove 'accountId', 123, {sessionId: 789}

    rels = relcache.get 'accountId', 123

    rels.should.exist
    rels.should.eql {sessionId: [456]}
    done()

  it 'should remove the last relationship', (done) ->
    relcache.add 'accountId', 123, {sessionId: 789}
    relcache.remove 'accountId', 123, {sessionId: 789}

    rels = relcache.get 'accountId', 123

    rels.should.exist
    rels.should.eql {}
    done()

  it 'should remove reverse relationship', (done) ->
    relcache.add 'accountId', 123, {sessionId: 789}
    relcache.remove 'accountId', 123, {sessionId: 789}

    rels = relcache.get 'sessionId', 789

    rels.should.exist
    rels.should.eql {}
    done()

  it 'should import data', (done) ->
    relcache.import {
      sessionId:
        '123':
          accountId: 456
    }

    rels = relcache.get 'sessionId', 123

    rels.should.exist
    rels.should.eql {accountId: 456}
    done()

  it 'should unset all relations', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456, foo: 'bar'}
    relcache.unset 'sessionId', 123

    rels = relcache.get 'sessionId', 123

    rels.should.exist
    rels.should.eql {}
    done()

  it 'should unset all reverse relations', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456}
    relcache.set 'sessionId', 123, {foo: 'stuff'}
    relcache.unset 'sessionId', 123

    r1 = relcache.get 'accountId', 456
    r2 = relcache.get 'foo', 'stuff'

    for r in [r1, r2]
      r.should.exist
      r.should.eql {}
    done()

  it 'should unset target relation', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456}
    relcache.set 'sessionId', 123, {foo: 'stuff'}
    relcache.unset 'sessionId', 123, 'accountId'

    rels = relcache.get 'sessionId', 123

    rels.should.exist
    rels.should.eql {foo: 'stuff'}
    done()

  it 'should unset target reverse relation', (done) ->
    relcache.set 'sessionId', 123, {accountId: 456}
    relcache.set 'sessionId', 123, {stuff: 'foo'}
    relcache.unset 'sessionId', 123, 'accountId'

    rels = relcache.get 'accountId', 456

    rels.should.exist
    rels.should.eql {}
    done()

  it 'should not unset non-related reverse relation', (done) ->
    relcache.set 'sessionId', 789, {name: 'Bob'}
    relcache.set 'sessionId', 123, {name: 'Bob'}
    relcache.unset 'sessionId', 123, 'name'

    rels = relcache.get 'name', 'Bob'

    rels.should.exist
    rels.should.eql {sessionId: [789]}
    done()

  it 'when set overrides a value it should update the reverse relation', (done) ->
    relcache.set 'sessionId', 123, {name: 'Bob'}
    relcache.set 'sessionId', 123, {name: 'Bobby'}

    rels = relcache.get 'name', 'Bob'
    rels.should.exist
    rels.should.eql {}

    rels = relcache.get 'name', 'Bobby'
    rels.should.exist
    rels.should.eql {sessionId: [123]}
    done()

  it 'set should emit two add events', (done) ->
    relcache.once 'add', ({key, value, relation}) ->
      key.should.eql 'sessionId'
      value.should.eql 123
      relation.should.eql {accountId: 456}
      current = relcache.get key, value
      current.should.eql relation

      relcache.once 'add', ({key, value, relation}) ->
        key.should.eql 'accountId'
        value.should.eql 456
        relation.should.eql {sessionId: 123}
        current = relcache.get key, value
        current.should.eql {sessionId: [123]}

        done()

    relcache.set 'sessionId', 123, {accountId: 456}

  it 'should emit two remove events', (done) ->
    relcache.once 'remove', ({key, value, targets}) ->
      key.should.eql 'accountId'
      value.should.eql 456
      targets.should.eql {sessionId: 123}
      current = relcache.get key, value
      current.should.eql {sessionId: [123]}

      relcache.once 'remove', ({key, value, targets}) ->
        key.should.eql 'sessionId'
        value.should.eql 123
        targets.should.eql {accountId: 456}
        current = relcache.get key, value
        current.should.eql {accountId: 456}

        done()

    relcache.set 'sessionId', 123, {accountId: 456}
    relcache.unset 'sessionId', 123

  it 'remove should emit two unset events', (done) ->
    relcache.once 'remove', ({key, value, targets}) ->
      key.should.eql 'sessionId'
      value.should.eql [789]
      targets.should.eql {accountId: 123}
      current = relcache.get key, value
      current.should.eql {accountId: [123]}

      relcache.once 'remove', ({key, value, targets}) ->
        key.should.eql 'accountId'
        value.should.eql 123
        targets.should.eql {sessionId: 789}
        current = relcache.get key, value
        current.should.eql {sessionId: [789]}

      done()

    relcache.add 'accountId', 123, {sessionId: 789}
    relcache.remove 'accountId', 123, {sessionId: 789}
