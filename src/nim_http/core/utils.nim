import macros, asyncdispatch, asynchttpserver, macrocache, tables, strutils, uri, options, sequtils

template getOrElse*[T](s: seq[T], default: T): T  =
  if s.len > 0: s[0] else: default  

template headOption*[T](s: seq[T]): Option[T] =
  if s.len > 0: some[T](s[0]) else: none[T]()

template getOrElse*[T](s: Option[T], default: T): T  =
  if s.isSome : s.get else: default

proc parseOrNone*[T](s: string):  Option[T] =
  when T is int:
    try: some(parseInt(s))   except: none[T]()
  elif T is float:
    try: some(parseFloat(s)) except: none[T]()
  elif T is bool:
    try: some(parseBool(s))  except: none[T]()
  elif T is string:
    some(s)
  else:
    discard

template QueryOpt*[T](key: static[string]): Option[T] =
  static:
    assert(T is int or T is float or T is bool or T is string or T is seq, "[nim_http] Unsupported type for QueryOpt ❌")
  this.request.url.query
    .split("&")
    .mapIt(it.split("=", maxsplit = 1))
    .filterIt(it.len == 2 and it[0] == key)
    .mapIt(decodeUrl(it[1]))
    .headOption()
    .flatMap(parseOrNone[T])

template QuerySeq*[T](key: static[string]): seq[T] =
  static:
    assert(T is int or T is float or T is bool or T is string, "[nim_http] Unsupported type for QuerySeq ❌")
  this.request.url.query
    .split("&")
    .mapIt(it.split("=", maxsplit = 1))
    .filterIt(it.len == 2 and it[0] == key)
    .mapIt(decodeUrl(it[1]))
    .mapIt(parseOrNone[T](it))
    .filterIt(it.isSome)
    .mapIt(it.get)

template Query*[T](key: static[string], default: T): T =
  QueryOpt[T](key).getOrElse(default)