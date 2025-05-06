import ../../nim_http/core/[controller, di, guard, exception]
import ../../libs/auth/auth_guard, options, json
import ./services/[user, log]

type UserDto = ref object
  username: string  

Controller Home:

  proc index() {.get("/index"), useGuards(AuthGuard).} =
    Ok "Hello from HomeController! " 

  proc users(
    id   {.param.}: int,
    name {.query.}: string,
    user {.body.}:  UserDto
  ) {.post("/users/:id").} =
    Ok user

  proc accounts(id {.param.}: int) {.get("/account/:id").} =
    Ok "Hello from accounts! " & $id

  proc html() {.get.} =
    let userService = inject(UserService)
    echo userService.name
    Ok "<html>dm</html>"