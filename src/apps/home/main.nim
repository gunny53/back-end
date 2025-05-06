import ../../nim_http/core/[controller, di, guard, exception]
import ../../libs/auth/auth_guard, options, json
import ./services/[user, log]

type UserDto = ref object
  username: string  

Controller Home("api/v1"):

  [HttpGet("index")]
  [UseGuards(AuthGuard)]
  proc index() = Http200 "Hello from HomeController! " 

  [HttpPost("users/:id")]
  [UseGuards(AuthGuard)]
  proc users(
    id   {.param.}: int,
    name {.query.}: string,
    user {.body.}:  UserDto
  ) = Http200 user

  [HttpGet("account/:id")]
  proc accounts(
    id   {.param.}: int,
    name {.query.}: string
  ) =
    if name == "":
      Http400 "erro"
    Http200 "Hello from accounts! " & $id & ", name = " & name

  [HttpGet]
  proc html() =
    let userService = inject(UserService)
    echo userService.name
    Http200 "<html>dm</html>"