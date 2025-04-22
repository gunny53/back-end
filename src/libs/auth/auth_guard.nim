import asynchttpserver
import ../../nim_http/core/[guard, exception]

type AuthGuard* = ref object of Guard
  exception: UnauthorizedException = UNAUTHORIZED("Yêu cầu đăng nhập")

method canActivate*(self: AuthGuard, req: Request): bool =
  if (req.headers.hasKey("Authorization")):
    let token = req.headers["Authorization"]
    echo token
    return token == "Bearer valid_token"
  raise self.exception

template useGuards*(guards: typed) {.pragma.}