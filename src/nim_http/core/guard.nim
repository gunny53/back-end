import asynchttpserver, di

type Guard* = ref object of SingletonObj
  request: Request

method canActivate*(self: Guard, req: Request): bool {.base, gcsafe.} = return true