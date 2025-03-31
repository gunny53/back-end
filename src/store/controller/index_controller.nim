import asyncdispatch, asynchttpserver
import ../../packages/common/decorators/core/controller
import ../../packages/common/decorators/core/http

Controller("/store"):
  GET(""):
    proc getAdmins(req: Request) {.async.} = await req.Ok("store")

  POST(""):
    proc te(req: Request) {.async.} = await req.Ok(req.body)
        