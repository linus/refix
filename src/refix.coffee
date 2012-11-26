commands = require 'redis/lib/commands'

first =
  proxy: (command, prefix, db) ->
    (key, args...) ->
      db[command] prefix + key, args...

  commands: [
    'append'
    'decr'
    'decrby'
    'dump'
    'exists'
    'expire'
    'expireat'
    'get'
    'getbit'
    'getrange'
    'getset'
    'hdel'
    'hexists'
    'hget'
    'hgetall'
    'hincrby'
    'hincrbyfloat'
    'hkeys'
    'hlen'
    'hmget'
    'hmset'
    'hset'
    'hsetnx'
    'hvals'
    'incr'
    'incrby'
    'incrbyfloat'
    'lindex'
    'linsert'
    'llen'
    'lpop'
    'lpush'
    'lpushx'
    'lrange'
    'lrem'
    'lset'
    'ltrim'
    'move'
    'persist'
    'pexpire'
    'pexpireat'
    'psetex'
    'pttl'
    'publish'
    'restore'
    'rpop'
    'rpush'
    'rpushx'
    'sadd'
    'scard'
    'set'
    'setbit'
    'setex'
    'setnx'
    'setrange'
    'sismember'
    'smembers'
    'spop'
    'srandmember'
    'srem'
    'strlen'
    'ttl'
    'type'
    'zadd'
    'zcard'
    'zcount'
    'zincrby'
    'zrange'
    'zrangebyscore'
    'zrank'
    'zrem'
    'zremrangebyrank'
    'zremrangebyscore'
    'zrevrange'
    'zrevrangebyscore'
    'zrevrank'
    'zscore'
  ]

all =
  proxy: (command, prefix, db) ->
    (keys...) ->
      prefixed = prefixKeys prefix, keys
      db[command] prefixed...

  commands: [
    'del'
    'psubscribe'
    'punsubscribe'
    'subscribe'
    'unsubscribe'
    'watch'
    'rpoplpush'
    'mget'
    'rename'
    'renamenx'
    'sdiff'
    'sdiffstore'
    'sinter'
    'sinterstore'
    'sunion'
    'sunionstore'
  ]

exceptFirst =
  proxy: (command, prefix, db) ->
    (arg, keys...) ->
      prefixed = prefixKeys prefix, keys
      db[command] arg, prefixed...

  commands: [
    'bitop'
  ]

exceptLast =
  proxy: (command, prefix, db) ->
    (keys..., arg, cb) ->
      if typeof cb is 'function'
        prefixed = prefixKeys prefix, keys
        db[command] prefixed..., arg, cb
      else
        keys.push arg
        arg = cb
        prefixed = prefixKeys prefix, keys
        db[command] prefixed..., arg

  commands: [
    'blpop'
    'brpop'
    'brpoplpush'
    'smove'
  ]

everySecond =
  proxy: (command, prefix, db) ->
    (args...) ->
      prefixed = []
      for arg, index in args
        if index % 2 or index is args.length - 1
          prefixed.push arg
        else
          prefixed.push prefix + arg

      db[command] prefixed...

  commands: [
    'mset'
    'msetnx'
  ]

migrate =
  proxy: (command, prefix, db) ->
    (host, port, key, dest, timeout, next) ->
      db[command] host, port, prefix + key, dest, timeout, next

  commands: [
    'migrate'
  ]

dynamic =
  proxy: (command, prefix, db) ->
    (dest, numKeys, args...) ->
      keys = args.splice 0, numKeys
      prefixed = prefixKeys prefix, keys

      db[command] prefix + dest, numKeys, prefixed..., args...

  commands: [
    'zinterstore'
    'zunionstore'
  ]

sort =
  proxy: (command, prefix, db) ->
    (key, args...) ->
      prefixed = []
      lastArg = ''
      for arg in args
        if lastArg.toLowerCase() is 'get'
          prefixed.push prefix + arg
        else
          prefixed.push arg

        lastArg = arg

      db[command] prefix + key, prefixed...

  commands: [
    'sort'
  ]

multi =
  proxy: (command, prefix, db) ->
    ->
      prefixer(db.multi()) prefix

  commands: [
    'multi'
  ]

handlers = [
  first
  all
  exceptFirst
  exceptLast
  everySecond
  migrate
  dynamic
  sort
  multi
]

prefixKeys = (prefix, keys) ->
  prefixed = for key in keys
    if typeof key is 'function'
      key
    else
      prefix + key

module.exports = prefixer = (db) ->
  (prefix) ->
    proxy = {}

    proxyCommand = (command) ->
      proxy[command] = -> db[command].apply db, arguments

    for command in commands
      for handler in handlers when command in handler.commands
        proxy[command] = handler.proxy command, prefix, db

      # Proxy any unproxied commands unchanged
      proxyCommand command unless command of proxy

    return proxy
