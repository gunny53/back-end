## Phase B unit tests — Route IR and compile-time registry.

import unittest, tables, strutils

import nim_http/core/route/ir

# ---------------------------------------------------------------------------
# computeStaticMask
# ---------------------------------------------------------------------------

suite "phase b ir: computeStaticMask":
  test "all-static path sets all bits":
    # /users/posts has 2 segments → bits 0 and 1 are 1
    let mask = computeStaticMask("/users/posts")
    check (mask and 1u64) == 1u64
    check (mask and 2u64) == 2u64

  test "pure param path sets no bits":
    let mask = computeStaticMask("/:id")
    check mask == 0u64

  test "mixed path sets only static-position bits":
    # /users/:id/posts → segments: users (bit0=1), :id (bit1=0), posts (bit2=1)
    let mask = computeStaticMask("/users/:id/posts")
    check (mask and 1u64) == 1u64   # users at bit 0
    check (mask and 2u64) == 0u64   # :id at bit 1 → not set
    check (mask and 4u64) == 4u64   # posts at bit 2

  test "root path has mask 0":
    check computeStaticMask("/") == 0u64

  test "empty string has mask 0":
    check computeStaticMask("") == 0u64

# ---------------------------------------------------------------------------
# computeSegmentCount
# ---------------------------------------------------------------------------

suite "phase b ir: computeSegmentCount":
  test "root path has 0 segments":
    check computeSegmentCount("/") == 0

  test "empty string has 0 segments":
    check computeSegmentCount("") == 0

  test "single segment":
    check computeSegmentCount("/users") == 1

  test "two segments":
    check computeSegmentCount("/users/posts") == 2

  test "three segments with params":
    check computeSegmentCount("/users/:id/posts") == 3

# ---------------------------------------------------------------------------
# computeParamNames
# ---------------------------------------------------------------------------

suite "phase b ir: computeParamNames":
  test "no params returns empty seq":
    check computeParamNames("/users/posts") == newSeq[string]()

  test "single param":
    check computeParamNames("/users/:id") == @["id"]

  test "multiple params in order":
    check computeParamNames("/users/:userId/posts/:postId") == @["userId", "postId"]

  test "root path":
    check computeParamNames("/") == newSeq[string]()

# ---------------------------------------------------------------------------
# computeRouteKey
# ---------------------------------------------------------------------------

suite "phase b ir: computeRouteKey":
  test "same method + same template → same key":
    let k1 = computeRouteKey("GET", "/users/:id")
    let k2 = computeRouteKey("GET", "/users/:id")
    check k1 == k2

  test "different method → different key":
    let k1 = computeRouteKey("GET",  "/users/:id")
    let k2 = computeRouteKey("POST", "/users/:id")
    check k1 != k2

  test "different templates with same shape share key":
    # /users/:id and /posts/:slug both have cnt=2, mask=1 (bit0 static, bit1 param)
    let k1 = computeRouteKey("GET", "/users/:id")
    let k2 = computeRouteKey("GET", "/posts/:slug")
    check k1 == k2

  test "different shapes produce different keys":
    let k1 = computeRouteKey("GET", "/users")
    let k2 = computeRouteKey("GET", "/users/:id")
    check k1 != k2

# ---------------------------------------------------------------------------
# makeRouteIREntry
# ---------------------------------------------------------------------------

suite "phase b ir: makeRouteIREntry":
  test "entry captures rawPath":
    let e = makeRouteIREntry("GET", "/users/:id")
    check e.rawPath == "/users/:id"

  test "entry captures param names":
    let e = makeRouteIREntry("DELETE", "/users/:userId/posts/:postId")
    check e.paramNames == @["userId", "postId"]

  test "entry key matches computeRouteKey":
    let e = makeRouteIREntry("POST", "/articles/:slug/comments")
    check e.key == computeRouteKey("POST", "/articles/:slug/comments")

# ---------------------------------------------------------------------------
# buildRouteIndex
# ---------------------------------------------------------------------------

suite "phase b ir: buildRouteIndex":
  test "empty manifest produces empty index":
    let idx = buildRouteIndex(newSeq[(string, string)]())
    check idx.len == 0

  test "single route is indexed correctly":
    let idx = buildRouteIndex(@[("GET", "/users")])
    let key = computeRouteKey("GET", "/users")
    check idx.hasKey(key)
    check idx[key].len == 1
    check idx[key][0].rawPath == "/users"

  test "two distinct-shape routes produce two keys":
    let idx = buildRouteIndex(@[
      ("GET",  "/users"),
      ("POST", "/users"),
    ])
    check idx.len == 2

  test "conflicting routes end up in same bucket":
    # /users/:id and /posts/:slug share the same key shape
    let idx = buildRouteIndex(@[
      ("GET", "/users/:id"),
      ("GET", "/posts/:slug"),
    ])
    let key = computeRouteKey("GET", "/users/:id")
    check idx.hasKey(key)
    check idx[key].len == 2

  test "hasConflict returns false for clean index":
    let idx = buildRouteIndex(@[
      ("GET",  "/users"),
      ("POST", "/users"),
      ("GET",  "/users/:id"),
    ])
    check not idx.hasConflict()

  test "hasConflict returns true when shapes collide":
    let idx = buildRouteIndex(@[
      ("GET", "/users/:id"),
      ("GET", "/posts/:slug"),
    ])
    check idx.hasConflict()

  test "listConflicts returns conflicting pairs":
    let idx = buildRouteIndex(@[
      ("GET", "/users/:id"),
      ("GET", "/posts/:slug"),
    ])
    let conflicts = idx.listConflicts()
    check conflicts.len == 1
    check conflicts[0][1].len == 2
