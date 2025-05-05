import ../../nim_http/core/[controller, di, guard, exception]
import ../../libs/auth/auth_guard, options, json
import ./services/[user_service, log_service]

type UserDto = ref object
  username: string  

Controller Home:
  let uService {.inject, gcsafe.}: UserService

  proc index() {.get("/index"), useGuards(AuthGuard).} =
    Ok "Hello from HomeController! " 

  proc users(
    id   {.param.}: int,
    name {.query.}: string,
    user {.body.}:  UserDto
  ) {.post("/users/:id").} =
    Ok user

  proc accounts() {.get("/account/:id").} =
    Ok "Hello from accounts! " 

  proc html() {.get.} =
    echo uService.name
    Ok "<html>dm</html>"