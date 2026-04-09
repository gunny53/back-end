## Phase C unit tests — generated dispatcher (RouteDispatcher).

import unittest, tables, asynchttpserver

import nim_http/core/route/ir
import nim_http/core/route/dispatch

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc makeEntry(meth, path: string): DispatchEntry =
  ## Creates a DispatchEntry with nil detail for structural testing.
  DispatchEntry(irEntry: makeRouteIREntry(meth, path), detail: nil)

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

suite "phase c dispatch: newRouteDispatcher":
  test "new dispatcher is empty":
    let d = newRouteDispatcher()
    check d.routeCount() == 0
    check not d.isBuilt()

# ---------------------------------------------------------------------------
# register
# ---------------------------------------------------------------------------

suite "phase c dispatch: register":
  test "registering one route increases route count":
    let d = newRouteDispatcher()
    let entry = makeRouteIREntry("GET", "/ping")
    d.register(entry, nil)
    check d.isBuilt()
    check d.routeCount() == 1

  test "registering same-shape routes accumulates in bucket":
    let d = newRouteDispatcher()
    let e1 = makeRouteIREntry("GET", "/ping")
    let e2 = makeRouteIREntry("GET", "/pong")
    # Both share the same (method, segmentCount) key — both are kept in the bucket
    d.register(e1, nil)
    d.register(e2, nil)
    check d.routeCount() == 2

  test "routes with distinct keys are both kept":
    let d = newRouteDispatcher()
    d.register(makeRouteIREntry("GET",  "/users"),      nil)
    d.register(makeRouteIREntry("POST", "/users"),      nil)
    d.register(makeRouteIREntry("GET",  "/users/:id"),  nil)
    check d.routeCount() == 3

# ---------------------------------------------------------------------------
# routeCount / isBuilt
# ---------------------------------------------------------------------------

suite "phase c dispatch: routeCount and isBuilt":
  test "routeCount tracks additions":
    let d = newRouteDispatcher()
    check d.routeCount() == 0
    d.register(makeRouteIREntry("GET", "/a"), nil)
    check d.routeCount() == 1
    d.register(makeRouteIREntry("GET", "/a/b"), nil)
    check d.routeCount() == 2

  test "isBuilt returns false for empty dispatcher":
    let d = newRouteDispatcher()
    check not d.isBuilt()

  test "isBuilt returns true after first registration":
    let d = newRouteDispatcher()
    d.register(makeRouteIREntry("DELETE", "/items/:id"), nil)
    check d.isBuilt()

# ---------------------------------------------------------------------------
# RouteIREntry slot layout sanity checks used by dispatcher
# ---------------------------------------------------------------------------

suite "phase c dispatch: slot layout":
  test "param slot positions match segment indices":
    let e = makeRouteIREntry("GET", "/users/:userId/posts/:postId")
    check e.paramNames.len == 2
    check e.paramNames[0] == "userId"
    check e.paramNames[1] == "postId"

  test "static-only route has empty paramNames":
    let e = makeRouteIREntry("GET", "/health/live")
    check e.paramNames.len == 0

  test "root route has empty paramNames and zero segments":
    let e = makeRouteIREntry("GET", "/")
    check e.paramNames.len == 0
    check e.key.segmentCount == 0

# ---------------------------------------------------------------------------
# buildFrom with empty manifest
# ---------------------------------------------------------------------------

suite "phase c dispatch: buildFrom empty manifest":
  test "buildFrom empty manifest leaves dispatcher empty":
    let d = newRouteDispatcher()
    d.buildFrom(newSeq[(string, string)]())
    check not d.isBuilt()
    check d.routeCount() == 0
