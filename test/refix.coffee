db = {}
refix = require('../lib/refix')
refixed = null

exports.setUp = (callback) ->
  db = {}
  refixed = refix db
  callback()

exports.first = (test) ->
  test.expect 2

  p = refixed 'foo'

  db.set = (key, val, next) ->
    test.equal key, 'foobar'
    test.equal val, 'baz'
    next()

  p.set 'bar', 'baz', ->
    test.done()

exports.all = (test) ->
  test.expect 2

  p = refixed 'foo'

  db.del = (key1, key2, next) ->
    test.equal key1, 'foo1'
    test.equal key2, 'foo2'
    next()

  p.del '1', '2', ->
    test.done()

exports.exceptFirst = (test) ->
  test.expect 4

  p = refixed 'foo'

  db.bitop = (operation, dest, src1, src2, next) ->
    test.equal operation, 'AND'
    test.equal dest, 'foodest'
    test.equal src1, 'foosrc1'
    test.equal src2, 'foosrc2'
    next()

  p.bitop 'AND', 'dest', 'src1', 'src2', ->
    test.done()

exports.exceptLast = (test) ->
  test.expect 3

  p = refixed 'foo'

  db.blpop = (key1, key2, timeout, next) ->
    test.equal key1, 'fookey1'
    test.equal key2, 'fookey2'
    test.equal timeout, 17
    next()

  p.blpop 'key1', 'key2', 17, ->
    test.done()

exports.everySecond = (test) ->
  test.expect 4

  p = refixed 'foo'

  db.mset = (key1, val1, key2, val2, next) ->
    test.equal key1, 'fookey1'
    test.equal val1, 'val1'
    test.equal key2, 'fookey2'
    test.equal val2, 'val2'
    next()

  p.mset 'key1', 'val1', 'key2', 'val2', ->
    test.done()

exports.migrate = (test) ->
  test.expect 5

  p = refixed 'foo'

  db.migrate = (host, port, key, dest, timeout, next) ->
    test.equal host, 'host'
    test.equal port, 4711
    test.equal key, 'fookey'
    test.equal dest, 'dest'
    test.equal timeout, 17
    next()

  p.migrate 'host', 4711, 'key', 'dest', 17, ->
    test.done()


exports.dynamic = (test) ->
  test.expect 6

  p = refixed 'foo'

  db.zinterstore = (dest, numKeys, key1, key2, weights, w1, w2, next) ->
    test.equal dest, 'foodest'
    test.equal key1, 'fookey1'
    test.equal key2, 'fookey2'
    test.equal weights, 'weights'
    test.equal w1, 2
    test.equal w2, 3
    next()

  p.zinterstore 'dest', 2, 'key1', 'key2', 'weights', 2, 3, ->
    test.done()

exports.sort = (test) ->
  test.expect 3

  p = refixed 'foo'

  db.sort = (key, _by, nosort, g1, p1, next) ->
    test.equal key, 'foolist'
    test.equal g1, 'get'
    test.equal p1, 'foo*'
    next()

  p.sort 'list', 'by', 'nosort', 'get', '*', ->
    test.done()

exports.multi = (test) ->
  test.expect 6

  p = refixed 'foo'

  db.multi = ->
    get: (key) ->
      test.equal key, 'fook1'
    set: (key, val) ->
      test.equal key, 'fook2'
      test.equal val, 'v'
    zunionstore: (dest, numKeys, src1, src2) ->
      test.equal dest, 'foodest'
      test.equal src1, 'foosrc1'
      test.equal src2, 'foosrc2'
    exec: (next) -> next()

  m = p.multi()
  m.get 'k1'
  m.set 'k2', 'v'
  m.zunionstore 'dest', 2, 'src1', 'src2'
  m.exec ->
    test.done()
