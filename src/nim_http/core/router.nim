import macros, asynchttpserver, strutils

type RouteConfig* = ref object
  httpMethod*: HttpMethod
  path*: string
  handler*: NimNode
  children*: seq[RouteConfig]

var routeTree* = newSeq[RouteConfig]()

macro path*(routePath: static[string], component: auto, httpMethod: static[HttpMethod] = HttpGet, body: untyped = nil): untyped =
  let route = quote do:
    RouteConfig(
      httpMethod: `httpMethod`,
      path: `routePath`,
      handler: `component`,
      children: @[]
    )

  if body.kind == nnkStmtList:
    # Có children, build children route
    var childrenStmts = newStmtList()
    for stmt in body:
      childrenStmts.add(stmt)

    result = quote do:
      var tmpRoute = `route`
      block:
        let parentRoute = tmpRoute
        block children:
          `childrenStmts`
        for child in routeTree:
          parentRoute.children.add(child)
        routeTree.setLen(0)
      routeTree.add(tmpRoute)
  else:
    result = quote do:
      routeTree.add(`route`)

macro routes*(body: untyped): untyped =
  result = newStmtList()
  result.add(body)

proc registerRouteRecursive*(prefix: string, route: RouteConfig) =
  let fullPath = (prefix & "/" & route.path).replace("//", "/")
  for child in route.children:
    registerRouteRecursive(fullPath, child)

proc registerRoutes*() =
  for route in routeTree:
    registerRouteRecursive("", route)
