import ../../nim_http/core/[controller, di, guard, utils]
import ../../libs/auth/auth_guard
import ./services/[user_service, log_service]

type HomeController* = ref object of BaseController
  userService {.inject.}: UserService
  logService  {.inject.}: LogService

Controller(HomeController):
  proc index() {.get("/index"), useGuards(AuthGuard).} =
    Ok "Hello from HomeController! " & this.userService.name

  proc users(id: int = Param("id")) {.get("/users/:id").} =
    echo id
    Ok("Hello from users! " & this.userService.name)

  proc accounts() {.get("/account/:id").} =
    Ok("Hello from accounts! " & this.userService.name)  