import asyncdispatch, asynchttpserver
import ../../packages/common/decorators/core/controller
import ../../packages/common/decorators/core/http

Controller("/store"):
  GET("/:id"):
    proc getAdmins(id: string): auto = Ok("id = ")