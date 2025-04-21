import asynchttpserver

type Guard* = ref object of RootObj
  request: Request

method canActivate*(self: Guard, req: Request): bool {.base, gcsafe.} =
  echo "Default guard"
  return true