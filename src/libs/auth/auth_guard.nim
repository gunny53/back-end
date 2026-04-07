import asynchttpserver
import ../../nim_http/pipeline/guard
import ../../nim_http/platform/exception
import ../../nim_http/kernel/di

class AuthGuard*() of Guard:

  method canActivate(self: AuthGuard, req: Request): bool =
    if (req.headers.hasKey("Authorization")):
      let token = req.headers["Authorization"]
      if $token != "Bearer valid_token":
        raise UNAUTHORIZED("Token không hợp lệ")
      return true
    raise UNAUTHORIZED("Yêu cầu đăng nhập")
