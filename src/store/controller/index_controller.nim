import asyncdispatch, asynchttpserver
import ../../packages/common/decorators/core/controller
import ../../packages/common/decorators/core/http

Controller("/store"):
  GET(""):
    proc getAdmins(): auto = Ok("store")

  POST("/test"):
    proc test(): auto = Ok("dm")