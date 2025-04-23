import ../../nim_http/core/[controller, di, guard]
import ../../libs/auth/auth_guard
import ./services/[user_service, log_service]

type HomeController* = ref object of BaseController
  userService {.inject.}: UserService
  logService  {.inject.}: LogService

Controller(HomeController):
  proc index*() {.get("index"), useGuards(AuthGuard).} =
    Ok "Hello from HomeController! " & this.userService.name

  proc about*() =
    Ok("Hello from HomeController! " & this.userService.name)