import asynchttpserver, tables, asyncdispatch
import ../guard, ../response

# Định nghĩa kiểu của 1 controller cơ bản
# BaseController là lớp cơ sở cho các controller khác, chứa các thuộc tính và phương thức chung
type BaseController* = ref object of RootObj
  request*: Request                                                        # Đối tượng Request đại diện cho HTTP request
  params*:  TableRef[string, string]     = newTable[string, string]()      # Bảng lưu trữ các tham số của request (path, params binds)
  guards*:  TableRef[string, seq[Guard]] = newTable[string, seq[Guard]]()  # Bảng lưu trữ các guards cho từng phương thức
  response: Response                     = Response()                      # Response object

# Hàm gắn request vào controller
proc processRequest*(this: BaseController, req: Request): BaseController =
  this.request          = req
  this.response.request = req
  return this

# Các template tương ứng với các status code thông dụng
template Http200*(content): untyped = this.response.send(Http200, content)
template Http400*(content): untyped = this.response.send(Http400, content)
template Http204*():        untyped = this.request.respond(Http204)
template Http201*(content): untyped = this.response.send(Http201, content)
template Http403*(content): untyped = this.response.send(Http403, content)
template Http404*(content): untyped = this.response.send(Http404, content)

# Hàm xử lý nghiệp vụ của controller khi đã vượt qua các tầng xác thực (guards)
proc invoke*(this: BaseController, handler: auto): Future[void] =
  let fn = proc (this: BaseController): Future[void] {.closure, async.} = handler(this)
  return fn(this)