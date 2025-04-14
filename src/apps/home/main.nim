import ../../nim_http/core/[controller, utils, di], options
import ./services/[user_service, log_service]

type HomeController* = ref object of BaseController
  userService* {.inject.}: UserService
  logService* {.inject.}: LogService

Controller(HomeController, ""):
  proc index*() =
    let name = QueryOpt[string]("name")
    let age  = QueryOpt[int]("age").getOrElse(9)
    echo name.getOrElse("aga")
    echo age
    Ok("Hello from HomeController!" &  this.userService.name)