import asynchttpserver
import ../../nim_http/core/[guard, exception]

type AuthGuard* = ref object of Guard

method canActivate*(self: AuthGuard, req: Request): bool =
  if (req.headers.hasKey("Authorization")):
    let token = req.headers["Authorization"]
    echo token
    return token == "Bearer valid_token"
  raise UNAUTHORIZED("Yêu cầu đăng nhập")

template useGuards*(guards: typed) {.pragma.}