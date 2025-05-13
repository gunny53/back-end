import asynchttpserver, di, response, asyncdispatch

type Interceptor* = ref object of SingletonObj

method intercept*(this: Interceptor, ctx: Request, next: proc(): Future[Response]): Future[Response] {.base, gcsafe.} = discard