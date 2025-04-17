import asyncdispatch, asynchttpserver, utils

type Guard* = ref object of RootObj
  request: Request

proc canActivate*(self: Guard, req: Request): bool = 
  return false

type AuthGuard* = ref object of Guard

proc canActivate*(self: AuthGuard, req: Request): bool =
  echo "asdasdas"
  if (req.headers.hasKey("Authorization")):
    let token = req.headers["Authorization"]
    return token == "Bearer valid_token"
  return false

template authGuard*(): AuthGuard {.pragma.}