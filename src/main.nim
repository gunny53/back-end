import asynchttpserver, asyncdispatch, tables, sequtils, strutils
import packages/logger/console
import packages/router/route_resolver

# Controllers
# import home/controller/index_controller
import store/controller/index_controller

const COLUMNS: seq[string] = @["METHOD", "PATH", "FILE PATH"]

proc logServerStart(port: Port) =
  # Column width calculate
  let column1Width = router.routes.keys  .toSeq.mapIt(($it[1]).len).foldl(a.max(b), 0).max(COLUMNS[0].len)
  let column2Width = router.routes.keys  .toSeq.mapIt(it[0].len)   .foldl(a.max(b), 0).max(COLUMNS[1].len)
  let column3Width = router.routes.values.toSeq.mapIt(it[1].len)   .foldl(a.max(b), 0).max(COLUMNS[2].len)

  # Write header col 1
  echo Default,
    "┌",
      repeat('-', column1Width + 2), "┬",
      repeat('-', column2Width + 2), "┬",
      repeat('-', column3Width + 2),
    "┐"

  # Write header col 2  
  echo Default,
    "| ",
      Green,  COLUMNS[0].alignLeft(column1Width), Default, " | ",
      Yellow, COLUMNS[1].alignLeft(column2Width), Default, " | ",
              COLUMNS[2].alignLeft(column3Width),
    " |"

  # Write header col 3
  echo Default,
    "├",
      repeat('-', column1Width + 2), "┼",
      repeat('-', column2Width + 2), "┼",
      repeat('-', column3Width + 2),
    "┤"

  # Write body rows
  for key, value in router.routes:
    echo Default,
      "| ",
        Green, ($key[1]).alignLeft(column1Width), Default, " | ",
        Yellow,   key[0].alignLeft(column2Width), Default, " | ",
          value.filePath.alignLeft(column3Width),
      " |"

  # Write footer
  echo Default,
    "└",
      repeat('-', column1Width + 2), "┴",
      repeat('-', column2Width + 2), "┴",
      repeat('-', column3Width + 2),
    "┘"

let port = Port(8082)
logServerStart(port)
echo "[INFO] Server started on ", ConsoleColor.Green, "http://localhost:", port.int

waitFor newAsyncHttpServer().serve(
  port,
  proc (req: Request) {.async.} =
    let routeKey = (req.url.path, req.reqMethod)  # Lấy cả đường dẫn + phương thức
    if router.routes.hasKey(routeKey): 
      await router.routes[routeKey].handler()(req)
    else: 
      await req.respond(Http404, "Not Found")
)