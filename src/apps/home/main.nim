import ../../nim_http/http/controller
import ../../libs/auth/auth_guard
import asyncdispatch

type UserDto = ref object
  username: string  

Controller Home("api/v1"):

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
    Http200 "<html>hello mf</html>"
