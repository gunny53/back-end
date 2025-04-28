import ../../nim_http/core/[controller, di, guard, exception]
import ../../libs/auth/auth_guard, options
import ./services/[user_service, log_service]

type HomeController = ref object of BaseController
  userService {.inject.}: UserService
  logService  {.inject.}: LogService

type UserDto = ref object
  username: string  

Controller(HomeController):
  proc index() {.get("/index"), useGuards(AuthGuard).} =
    Ok "Hello from HomeController! " & this.userService.name

  proc users(
      id {.param.}: int,
    name {.query.}: string,
    user {.body.}:  UserDto
  ) {.post("/users/:id").} =
    echo user.username
    Ok("Hello from users! " & this.userService.name & " id = " & $id & " name= " & name)

  proc accounts() {.get("/account/:id").} =
    Ok("Hello from accounts! " & this.userService.name)  

  proc html() {.get.} =
    Ok ("<h1>dm</h1>")  