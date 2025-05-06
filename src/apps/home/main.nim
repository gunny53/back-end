import ../../nim_http/core/[controller, di, guard, exception]
import ../../libs/auth/auth_guard, options, json
import ./services/[user, log]

type UserDto = ref object
  username: string  

Controller Home:

  proc index() {.get("/index"), useGuards(AuthGuard).} =
    Http200 "Hello from HomeController! " 

  proc users(
    id   {.param.}: int,
    name {.query.}: string,
    user {.body.}:  UserDto
  ) {.post("/users/:id").} =
    Http200 user

  proc accounts(id {.param.}: int, name {.query.}: string) {.get("/account/:id").} =
    if name == "":
      Http400 "erro"
    Http200 "Hello from accounts! " & $id & ", name = " & name

  proc html() {.get.} =
    let userService = inject(UserService)
    echo userService.name
    Http200 "<html>dm</html>"