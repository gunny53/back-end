import asynchttpserver, asyncdispatch

# Base http exception
type HttpException* = ref object of CatchableError
  statusCode*: HttpCode
  message*:    string
method catch(this: HttpException, req: Request): Future[void] {.base, async, gcsafe.} =
  await req.respond(this.statusCode, this.message, req.headers)

# Bad request
type BadRequestException* = ref object of HttpException
method catch(this: BadRequestException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)

# Conflict exception
type ConflictException* = ref object of HttpException
method catch(this: ConflictException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)

# Forbidden
type ForbiddenException* = ref object of HttpException
method catch(this: ForbiddenException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)

# GatewayTimeoutException
type GatewayTimeoutException* = ref object of HttpException
method catch(this: GatewayTimeoutException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)

# GoneException
type GoneException* = ref object of HttpException
method catch(this: GoneException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)

# HttpVersionNotSupportedException  
type HttpVersionNotSupportedException* = ref object of HttpException
method catch(this: HttpVersionNotSupportedException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)

# ImATeapotException
type ImATeapotException* = ref object of HttpException
method catch(this: ImATeapotException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)

# InternalServerErrorException
type InternalServerErrorException* = ref object of HttpException
method catch(this: InternalServerErrorException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)

# MethodNotAllowedException
type MethodNotAllowedException* = ref object of HttpException
method catch(this: MethodNotAllowedException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)    

# MisdirectedException
type MisdirectedException* = ref object of HttpException
method catch(this: MisdirectedException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)

# NotAcceptableException
type NotAcceptableException* = ref object of HttpException
method catch(this: NotAcceptableException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)  

# NotFoundException
type NotFoundException* = ref object of HttpException
method catch(this: NotFoundException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)    

# NotImplementedException
type NotImplementedException* = ref object of HttpException
method catch(this: NotImplementedException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)

# PreconditionFailedException
type PreconditionFailedException* = ref object of HttpException
method catch(this: PreconditionFailedException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)  

# RequestTimeoutException
type RequestTimeoutException* = ref object of HttpException
method catch(this: RequestTimeoutException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)   

# ServiceUnavailableException
type ServiceUnavailableException* = ref object of HttpException
method catch(this: ServiceUnavailableException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)

# UnauthorizedException
type UnauthorizedException* = ref object of HttpException
method catch(this: UnauthorizedException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)     

# UnprocessableEntityException
type UnprocessableEntityException* = ref object of HttpException
method catch(this: UnprocessableEntityException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req) 

# UnsupportedMediaTypeException
type UnsupportedMediaTypeException* = ref object of HttpException
method catch(this: UnsupportedMediaTypeException, req: Request): Future[void] {.async, gcsafe.} =
  await HttpException(this).catch(req)

# Constants for HttpExceptions
func UNAUTHORIZED*              (message: string): HttpException =            UnauthorizedException(statusCode: Http401, message: message)
func BAD_REQUEST*               (message: string): HttpException =              BadRequestException(statusCode: Http400, message: message)
func CONFLICT*                  (message: string): HttpException =                ConflictException(statusCode: Http409, message: message)
func FORBIDDEN*                 (message: string): HttpException =               ForbiddenException(statusCode: Http403, message: message)
func GATEWAY_TIMEOUT*           (message: string): HttpException =          GatewayTimeoutException(statusCode: Http504, message: message)
func GONE*                      (message: string): HttpException =                    GoneException(statusCode: Http410, message: message)
func HTTP_VERSION_NOT_SUPPORTED*(message: string): HttpException = HttpVersionNotSupportedException(statusCode: Http505, message: message)
func IM_A_TEAPOT*               (message: string): HttpException =               ImATeapotException(statusCode: Http418, message: message)
func INTERNAL_SERVER_ERROR*     (message: string): HttpException =     InternalServerErrorException(statusCode: Http500, message: message)
func METHOD_NOT_ALLOWED*        (message: string): HttpException =        MethodNotAllowedException(statusCode: Http405, message: message)
func MISDIRECTED*               (message: string): HttpException =             MisdirectedException(statusCode: Http421, message: message)
func NOT_ACCEPTABLE*            (message: string): HttpException =           NotAcceptableException(statusCode: Http406, message: message)
func NOT_FOUND*                 (message: string): HttpException =                NotFoundException(statusCode: Http404, message: message)
func NOT_IMPLEMENTED*           (message: string): HttpException =          NotImplementedException(statusCode: Http501, message: message)
func PRECONDITION_FAILED*       (message: string): HttpException =      PreconditionFailedException(statusCode: Http412, message: message)
func REQUEST_TIMEOUT*           (message: string): HttpException =          RequestTimeoutException(statusCode: Http408, message: message)
func SERVICE_UNAVAILABLE*       (message: string): HttpException =      ServiceUnavailableException(statusCode: Http503, message: message)
func UNPROCESSABLE_ENTITY*      (message: string): HttpException =     UnprocessableEntityException(statusCode: Http422, message: message)
func UNSUPPORTED_MEDIA_TYPE*    (message: string): HttpException =    UnsupportedMediaTypeException(statusCode: Http415, message: message)