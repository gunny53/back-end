import asynchttpserver, asyncdispatch, strutils, httpclient, options
import apps/home/routes
import nim_http/core/[controller, router]

waitFor newAsyncHttpServer().serve(
  Port(8082),
  proc (request: Request) {.async.} = await request.process
)
