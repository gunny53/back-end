import ../../nim_http/core/controller
import ../../libs/auth/auth_guard
import ./services/[user, log], asyncdispatch

type UserDto = ref object
  username: string  

Controller Home("api/v1"):
  let userService   = inject(UserService)
  let loggerService = inject(LogService)

  [GET("index")]
  [UseGuard(AuthGuard)]
  proc index() = Http200 "Hello from HomeController! " 

  [GET("users/:id")]
  [UseGuard(AuthGuard)]
  proc users(
    id   {.param.}: int,
    name {.query.}: string,
    user {.body.}:  UserDto
  ) = 
    Http200 user

  [GET("account/:id")]
  proc accounts(
    id   {.param.}: int,
    name {.query.}: string
  ) =
    if name == "":
      Http400 "erro"
    Http200 "Hello from accounts! " & $id & ", name = " & name

  [GET]
  proc html() =
    echo userService.name
    echo loggerService.mgs
    Http200 "<html>hello mf</html>"