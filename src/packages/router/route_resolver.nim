import macros, asynchttpserver, asyncdispatch, tables

type RouteHandler* = proc (things: varargs[string, `$`] = ""): proc (req: Request): Future[void] {.async, gcsafe.} {.async, gcsafe.}

type Router* = ref object
  routes*: Table[(string, HttpMethod), tuple[handler: RouteHandler, filePath: string]]
  
var router* {.threadvar.}: Router
router = Router(routes: initTable[(string, HttpMethod), tuple[handler: RouteHandler, filePath: string]]())

macro RouteMapping*(
  route: static[string],
  httpMethod: HttpMethod,
  body: untyped
): untyped =
  echo "[DEBUG] RouteMapping macro bắt đầu"

  if body.kind != nnkStmtList or body.len == 0 or body[0].kind != nnkProcDef:
    error("RouteMapping requires a proc definition")

  let originalProc = body[0]
  let procName = originalProc.name
  let filename = $lineInfo(originalProc)

  echo "[DEBUG] procName: ", repr(procName)
  echo "[DEBUG] filename: ", filename
  echo "[DEBUG] originalProc:\n", treeRepr(originalProc)

  let returnType = originalProc.params[0]
  let originalParams = originalProc.params[1..^1]

  echo "[DEBUG] returnType: ", treeRepr(returnType)
  echo "[DEBUG] originalParams:\n", treeRepr(newTree(nnkStmtList, originalParams))

  var newParams = newTree(nnkFormalParams, returnType)
  var callArgs: seq[NimNode] = @[]
  var injectedStmts = newStmtList()

  var hasReq = false

  echo "[DEBUG] Check req: Request tồn tại"

  for p in originalParams:
    echo "[DEBUG] Param: ", treeRepr(p)
    if p.kind == nnkIdentDefs and p.len >= 2:
      if p[1].kind == nnkIdent and p[1].strVal == "Request":
        hasReq = true
        newParams.add(p)
        callArgs.add(p[0])
        echo "[DEBUG] Đã có req: Request"
        break

  if not hasReq:
    echo "[DEBUG] Chưa có req: Request → thêm thủ công"
    let reqIdent = genSym(nskParam, "req") # an toàn hơn ident("req")
    let reqParam = newIdentDefs(reqIdent, ident("Request"), newEmptyNode())

    newParams.add(reqParam)
    callArgs.add(reqIdent) # dùng chính symbol đã tạo

  echo "[DEBUG] Bắt đầu duyệt các param để inject"
  for p in originalParams:
    if p.kind == nnkIdentDefs and p.len >= 2:
      let name = p[0]
      let typ  = p[1]
      if typ.kind == nnkIdent:
        echo "[DEBUG] Kiểu param: ", typ.strVal
        case typ.strVal
        of "string":
          echo "[DEBUG] Inject Query param: ", $name
          let defaultValue = newStmtList()  # Tạo danh sách câu lệnh mới
          defaultValue.add(quote do:
            var `name`: `typ` = "id_hard_code"  # Gán giá trị mặc định mới
          )

          let newIdentDef = newIdentDefs(p[0], p[1], defaultValue)  # Thêm giá trị mặc định vào tham số
          newParams.add(newIdentDef)  # Thêm tham số vào danh sách tham số mới
          callArgs.add(copyNimNode(p[0]))  # Thêm tham số vào danh sách đối số
        else:
          echo "[DEBUG] Giữ nguyên param: ", $name
          newParams.add(p)
          callArgs.add(name)
      else:
        echo "[DEBUG] Kiểu không xác định, giữ nguyên"
        newParams.add(p)
        callArgs.add(name)

  echo "[DEBUG] newParams sau khi inject:\n", treeRepr(newParams)

  let updatedProc = newTree(
    nnkProcDef,
    procName,
    newEmptyNode(),     # Generic params
    newEmptyNode(),     # Pragmas
    newParams,
    newEmptyNode(),     # Exception
    newEmptyNode(),     # Asynchronous
    copyNimTree(originalProc.body)
  )

  echo "[DEBUG] updatedProc:\n", treeRepr(updatedProc)

  let callOriginal = newCall(procName, callArgs)
  let finalBody = newStmtList(injectedStmts)
  finalBody.add quote do:
    discard `callOriginal`

  echo "[DEBUG] finalBody:\n", treeRepr(finalBody)
  let handler = quote do:
    proc (req: Request): Future[void] {.async.} =
      `injectedStmts`
      discard `callOriginal`

  result = quote do:
    `updatedProc`
    router.routes[(`route`, `httpMethod`)] = (`handler`, `filename`)