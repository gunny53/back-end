import asynchttpserver

type HttpException* = ref object of CatchableError
  statusCode: HttpCode
  message*:   string