import asynchttpserver, tables, asyncdispatch
import ../guard, ../response
import ../route/params

# Định nghĩa kiểu của 1 controller cơ bản
# BaseController là lớp cơ sở cho các controller khác, chứa các thuộc tính và phương thức chung
type BaseController* = ref object of RootObj
  request*:     Request                                                        # Đối tượng Request đại diện cho HTTP request
  params*:      TableRef[string, string]     = newTable[string, string]()      # Bảng lưu trữ các tham số của request (path, params binds)
  paramSlots*:  ParamSlots                   = emptyParamSlots()               # Phase D: slot-based zero-alloc param store
  guards*:      TableRef[string, seq[Guard]] = newTable[string, seq[Guard]]()  # Bảng lưu trữ các guards cho từng phương thức
  response:     Response                     = Response()                      # Response object

# Hàm gắn request vào controller
func processRequest*(this: BaseController, req: Request): BaseController =
  this.request          = req
  this.response.request = req
  return this

# Phase D: slot-based param lookup — prefers paramSlots over the legacy Table.
func getParam*(this: BaseController, name: string): string =
  ## Returns the path-parameter value for *name*.
  ## When the Phase-D dispatcher has bound ``paramSlots``, the lookup uses
  ## O(1)-per-slot scan with no Table access.  Falls back to ``params`` for
  ## legacy compatibility (e.g. when the old ``process`` path is used).
  if not this.paramSlots.isEmpty():
    return this.paramSlots.getParam(name)
  if not this.params.isNil and this.params.hasKey(name):
    return this.params[name]
  return ""

# Phase D: on-demand Table materialisation — call only when map-style
# access is required (e.g. JSON serialisation of all params).
proc materializeParams*(this: BaseController) =
  ## Populates ``params`` from ``paramSlots``.  No-op when ``paramSlots`` is
  ## empty or ``params`` has already been populated.
  if not this.paramSlots.isEmpty() and
     (this.params.isNil or this.params.len == 0):
    this.params = this.paramSlots.materialize()

# Hàm xử lý nghiệp vụ của controller khi đã vượt qua các tầng xác thực (guards)
proc invoke*(this: BaseController, handler: auto): Future[void] =
  let fn = proc (this: BaseController): Future[void] {.closure, async.} = handler(this)
  return fn(this)

# Hàm gắn guard vào proc handler
func addGuard*[T: Guard](this: BaseController, key: string, guard: T) =
  if not this.guards.hasKey(key):
    this.guards[key] = @[]
  this.guards[key].add(cast[Guard](guard))  

func getGuards*(this: BaseController, key: string): seq[Guard] =
  if not this.guards.hasKey(key):
    this.guards[key] = @[]
  return this.guards[key]

# Các template tương ứng với các status code thông dụng
template Http200*(content): untyped = this.response.send(Http200, content)
template Http400*(content): untyped = this.response.send(Http400, content)
template Http204*():        untyped = this.request.respond(Http204)
template Http201*(content): untyped = this.response.send(Http201, content)
template Http403*(content): untyped = this.response.send(Http403, content)
template Http404*(content): untyped = this.response.send(Http404, content)

# Bảng lưu các inst controller theo tên
let controllerRegistry*: TableRef[string, BaseController] = newTable[string, BaseController]()