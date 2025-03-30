import asyncdispatch, asynchttpserver
import ../../packages/common/decorators/core/controller
import ../../packages/common/decorators/core/http

Controller(""):
  GET("/store"):
    proc getAdmins(req: Request) {.async.} = await req.Ok("store")