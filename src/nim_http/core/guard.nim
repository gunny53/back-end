import asynchttpserver

type Guard* = ref object of RootObj
  request: Request

method canActivate*(self: Guard, req: Request): bool {.base, gcsafe.} =
  echo "Default guard"
  return true

type AuthGuard* = ref object of Guard

method canActivate*(self: AuthGuard, req: Request): bool =
  if (req.headers.hasKey("Authorization")):
    let token = req.headers["Authorization"]
    echo token
    return token == "Bearer valid_token"
  return false

template useGuards*(guards: typed) {.pragma.}