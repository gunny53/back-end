import asynchttpserver, asyncdispatch, json

# Base http exception
type HttpException* = ref object of Exception
  statusCode*: HttpCode
  message*:    string
method catch*(this: HttpException, req: Request): Future[void] {.base, async, gcsafe.} =
  if not req.headers.hasKey("Content-Type"):
    req.headers["Content-Type"] = "application/json"
  let mess = %*{"statusCode": this.statusCode.int, "message": this.message}
  await req.respond(this.statusCode, $mess, req.headers)

type
  BadRequestException*              = ref object of HttpException
  ConflictException*                = ref object of HttpException
  ForbiddenException*               = ref object of HttpException
  GatewayTimeoutException*          = ref object of HttpException
  GoneException*                    = ref object of HttpException
  HttpVersionNotSupportedException* = ref object of HttpException
  ImATeapotException*               = ref object of HttpException
  InternalServerErrorException*     = ref object of HttpException
  MethodNotAllowedException*        = ref object of HttpException
  MisdirectedException*             = ref object of HttpException
  NotAcceptableException*           = ref object of HttpException
  NotFoundException*                = ref object of HttpException
  NotImplementedException*          = ref object of HttpException
  PreconditionFailedException*      = ref object of HttpException
  RequestTimeoutException*          = ref object of HttpException
  ServiceUnavailableException*      = ref object of HttpException
  UnauthorizedException*            = ref object of HttpException
  UnprocessableEntityException*     = ref object of HttpException
  UnsupportedMediaTypeException*    = ref object of HttpException

# Constants for HttpExceptions
func UNAUTHORIZED*              (message: string = $Http401): HttpException =            UnauthorizedException(statusCode: Http401, message: message)
func BAD_REQUEST*               (message: string = $Http400): HttpException =              BadRequestException(statusCode: Http400, message: message)
func CONFLICT*                  (message: string = $Http409): HttpException =                ConflictException(statusCode: Http409, message: message)
func FORBIDDEN*                 (message: string = $Http403): HttpException =               ForbiddenException(statusCode: Http403, message: message)
func GATEWAY_TIMEOUT*           (message: string = $Http504): HttpException =          GatewayTimeoutException(statusCode: Http504, message: message)
func GONE*                      (message: string = $Http410): HttpException =                    GoneException(statusCode: Http410, message: message)
func HTTP_VERSION_NOT_SUPPORTED*(message: string = $Http505): HttpException = HttpVersionNotSupportedException(statusCode: Http505, message: message)
func IM_A_TEAPOT*               (message: string = $Http418): HttpException =               ImATeapotException(statusCode: Http418, message: message)
func INTERNAL_SERVER_ERROR*     (message: string = $Http500): HttpException =     InternalServerErrorException(statusCode: Http500, message: message)
func METHOD_NOT_ALLOWED*        (message: string = $Http405): HttpException =        MethodNotAllowedException(statusCode: Http405, message: message)
func MISDIRECTED*               (message: string = $Http421): HttpException =             MisdirectedException(statusCode: Http421, message: message)
func NOT_ACCEPTABLE*            (message: string = $Http406): HttpException =           NotAcceptableException(statusCode: Http406, message: message)
func NOT_FOUND*                 (message: string = $Http404): HttpException =                NotFoundException(statusCode: Http404, message: message)
func NOT_IMPLEMENTED*           (message: string = $Http501): HttpException =          NotImplementedException(statusCode: Http501, message: message)
func PRECONDITION_FAILED*       (message: string = $Http412): HttpException =      PreconditionFailedException(statusCode: Http412, message: message)
func REQUEST_TIMEOUT*           (message: string = $Http408): HttpException =          RequestTimeoutException(statusCode: Http408, message: message)
func SERVICE_UNAVAILABLE*       (message: string = $Http503): HttpException =      ServiceUnavailableException(statusCode: Http503, message: message)
func UNPROCESSABLE_ENTITY*      (message: string = $Http422): HttpException =     UnprocessableEntityException(statusCode: Http422, message: message)
func UNSUPPORTED_MEDIA_TYPE*    (message: string = $Http415): HttpException =    UnsupportedMediaTypeException(statusCode: Http415, message: message)