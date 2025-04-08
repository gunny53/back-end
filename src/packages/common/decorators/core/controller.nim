import macros, asynchttpserver, asyncdispatch, tables, options
import ../../../router/route_resolver

macro Controller*(prefix: static[string], body: untyped): untyped =
  result = newStmtList()

  for stmt in body:
    if ($stmt[0] in ["GET", "POST", "PUT", "DELETE"]):
      let updatedStmt = copyNimTree(stmt)
      updatedStmt[1]  = newLit(prefix & stmt[1].strVal)
      result.add updatedStmt
    else:
      result.add stmt

  result = newBlockStmt(result)
