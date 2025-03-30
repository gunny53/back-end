import asyncdispatch, asynchttpserver
import ../../packages/common/decorators/core/controller
import ../../packages/common/decorators/core/http

Controller(""):
  GET("/"):
    proc getAdmins(req: Request) {.async.} = await req.Ok("home")