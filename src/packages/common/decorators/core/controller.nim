import macros, asynchttpserver, asyncdispatch, tables, jsony, options
import ../../../router/route_resolver

macro Controller*(name: static[string], body: untyped): untyped =
  result = quote do:
    block: `body`