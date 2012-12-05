# The canonical list of redis commands
commands = require 'redis/lib/commands'

# All commands where the only key is the first argument
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

# All commands where all arguments (except an optional callback) are keys
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

# All commands where all arguments except the first is a key
exceptFirst =
  proxy: (command, prefix, db) ->
    (arg, keys...) ->
      prefixed = prefixKeys prefix, keys
      db[command] arg, prefixed...

  commands: [
    'bitop'
  ]

# All commands where all arguments except the last is a key
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

# All commands where every second argument is a key
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

# Special case for migrate
migrate =
  proxy: (command, prefix, db) ->
    (host, port, key, dest, timeout, next) ->
      db[command] host, port, prefix + key, dest, timeout, next

  commands: [
    'migrate'
  ]

# All commands where the key arguments are specified as an argument
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

# Eval is just like dynamic, but not prefixing the script
evil =
  proxy: (command, prefix, db) ->
    (script, numKeys, args...) ->
      keys = args.splice 0, numKeys
      prefixed = prefixKeys prefix, keys

      db[command] script, numKeys, prefixed..., args...

  commands: [
    'eval'
  ]

# Special case for sort
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

# Special case for multi, proxying the multi object itself
multi =
  proxy: (command, prefix, db) ->
    ->
      prefixer(db.multi(), true) prefix

  commands: [
    'multi'
  ]

# The list of command proxies
proxies = [
  first
  all
  exceptFirst
  exceptLast
  everySecond
  migrate
  dynamic
  evil
  sort
  multi
]

# Utility for prefixing all keys in an array, except if it's a function
# (for callbacks)
prefixKeys = (prefix, keys) ->
  prefixed = for key in keys
    if typeof key is 'function'
      key
    else
      prefix + key

# Main entry point
module.exports = prefixer = (db, chain) ->
  (prefix) ->
    proxy = {}

    # Proxy a command unchanged
    proxyCommand = (command) ->
      proxy[command] = -> db[command].apply db, arguments

    for command in commands
      # Find the proxy for this command
      for p in proxies when command in p.commands
        do (command) ->
          c = p.proxy command, prefix, db
          proxy[command] = ->
            r = c.apply db, arguments

            if chain then proxy else r

      # Proxy any unproxied commands unchanged
      proxyCommand command unless command of proxy

    return proxy
