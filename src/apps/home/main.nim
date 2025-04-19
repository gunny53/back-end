import ../../nim_http/core/[controller, di, utils, guard]
import ./services/[user_service, log_service]
import asynchttpserver

type HomeController* = ref object of BaseController
  userService* {.inject.}: UserService
  logService*  {.inject.}: LogService

Controller(HomeController):
  proc index*() {.useGuards([AuthGuard]).} =
    Ok "Hello from HomeController! " & this.userService.name

  proc about*() =
    Ok("Hello from HomeController! " & this.userService.name)