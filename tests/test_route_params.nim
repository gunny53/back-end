## Phase D unit tests — zero-alloc parameter binding (ParamSlots).

import unittest, tables

import nim_http/core/route/params

# ---------------------------------------------------------------------------
# emptyParamSlots
# ---------------------------------------------------------------------------

suite "phase d params: emptyParamSlots":
  test "isEmpty returns true":
    let s = emptyParamSlots()
    check s.isEmpty()

  test "len returns 0":
    let s = emptyParamSlots()
    check s.len == 0

  test "getParam returns empty string for any name":
    let s = emptyParamSlots()
    check s.getParam("id") == ""

  test "getParamAt returns empty string for any index":
    let s = emptyParamSlots()
    check s.getParamAt(0) == ""

# ---------------------------------------------------------------------------
# newParamSlots
# ---------------------------------------------------------------------------

suite "phase d params: newParamSlots":
  test "creates slots with correct len":
    let s = newParamSlots(@["id", "name"], @["42", "alice"])
    check s.len == 2

  test "isEmpty returns false for non-empty slots":
    let s = newParamSlots(@["id"], @["7"])
    check not s.isEmpty()

  test "values are stored in order":
    let s = newParamSlots(@["userId", "postId"], @["10", "20"])
    check s.getParamAt(0) == "10"
    check s.getParamAt(1) == "20"

  test "excess values are ignored":
    let s = newParamSlots(@["id"], @["1", "extra"])
    check s.len == 1
    check s.getParamAt(0) == "1"

  test "missing values default to empty string":
    let s = newParamSlots(@["a", "b", "c"], @["x"])
    check s.getParamAt(0) == "x"
    check s.getParamAt(1) == ""
    check s.getParamAt(2) == ""

# ---------------------------------------------------------------------------
# slotIndex
# ---------------------------------------------------------------------------

suite "phase d params: slotIndex":
  test "returns correct index for existing name":
    let layout: ParamLayout = @["userId", "postId"]
    check slotIndex(layout, "userId") == 0
    check slotIndex(layout, "postId") == 1

  test "returns -1 for missing name":
    let layout: ParamLayout = @["id"]
    check slotIndex(layout, "name") == -1

  test "returns -1 for empty layout":
    let layout: ParamLayout = @[]
    check slotIndex(layout, "id") == -1

# ---------------------------------------------------------------------------
# getParam
# ---------------------------------------------------------------------------

suite "phase d params: getParam":
  test "looks up value by name":
    let s = newParamSlots(@["category", "slug"], @["tech", "nim-lang"])
    check s.getParam("category") == "tech"
    check s.getParam("slug")     == "nim-lang"

  test "returns empty string for unknown name":
    let s = newParamSlots(@["id"], @["5"])
    check s.getParam("notExist") == ""

  test "returns empty string when isEmpty":
    let s = emptyParamSlots()
    check s.getParam("anything") == ""

# ---------------------------------------------------------------------------
# getParamAt
# ---------------------------------------------------------------------------

suite "phase d params: getParamAt":
  test "returns value at valid index":
    let s = newParamSlots(@["a", "b"], @["foo", "bar"])
    check s.getParamAt(0) == "foo"
    check s.getParamAt(1) == "bar"

  test "returns empty string for negative index":
    let s = newParamSlots(@["a"], @["v"])
    check s.getParamAt(-1) == ""

  test "returns empty string for out-of-range index":
    let s = newParamSlots(@["a"], @["v"])
    check s.getParamAt(5) == ""

# ---------------------------------------------------------------------------
# materialize
# ---------------------------------------------------------------------------

suite "phase d params: materialize":
  test "produces correct Table from slots":
    let s = newParamSlots(@["userId", "postId"], @["100", "200"])
    let t = s.materialize()
    check t.len == 2
    check t["userId"] == "100"
    check t["postId"] == "200"

  test "materializing empty slots returns empty table":
    let s = emptyParamSlots()
    let t = s.materialize()
    check t.len == 0

  test "materialize does not mutate slots":
    let s = newParamSlots(@["x"], @["42"])
    discard s.materialize()
    check s.getParam("x") == "42"
    check not s.isEmpty()

  test "each materialize call returns a fresh table":
    let s = newParamSlots(@["k"], @["v"])
    let t1 = s.materialize()
    let t2 = s.materialize()
    t1["extra"] = "yes"
    check not t2.hasKey("extra")

# ---------------------------------------------------------------------------
# extractSlotValues
# ---------------------------------------------------------------------------

suite "phase d params: extractSlotValues":
  test "extracts single param":
    let layout: ParamLayout = @["id"]
    let segs = @["users", "42"]
    let vals = extractSlotValues(layout, segs, "/users/:id")
    check vals.len == 1
    check vals[0] == "42"

  test "extracts two params in order":
    let layout: ParamLayout = @["userId", "postId"]
    let segs = @["users", "10", "posts", "20"]
    let vals = extractSlotValues(layout, segs, "/users/:userId/posts/:postId")
    check vals.len == 2
    check vals[0] == "10"
    check vals[1] == "20"

  test "empty path yields empty values":
    let layout: ParamLayout = @[]
    let vals = extractSlotValues(layout, @[], "/")
    check vals.len == 0

  test "static-only path yields empty values":
    let layout: ParamLayout = @[]
    let vals = extractSlotValues(layout, @["health", "live"], "/health/live")
    check vals.len == 0

  test "returns empty strings when segs are shorter than expected":
    let layout: ParamLayout = @["a", "b"]
    let vals = extractSlotValues(layout, @["x"], "/:a/:b")
    check vals.len == 2
    check vals[0] == "x"
    check vals[1] == ""

# ---------------------------------------------------------------------------
# Round-trip: extractSlotValues → newParamSlots → getParam
# ---------------------------------------------------------------------------

suite "phase d params: round-trip extraction and lookup":
  test "full flow: extract then getParam by name":
    let layout: ParamLayout = @["orgId", "teamId"]
    let segs = @["orgs", "42", "teams", "99"]
    let vals = extractSlotValues(layout, segs, "/orgs/:orgId/teams/:teamId")
    let slots = newParamSlots(layout, vals)
    check slots.getParam("orgId")  == "42"
    check slots.getParam("teamId") == "99"

  test "full flow: extract then getParamAt by index":
    let layout: ParamLayout = @["ver", "resource"]
    let segs = @["api", "v2", "users"]
    let vals = extractSlotValues(layout, segs, "/api/:ver/:resource")
    let slots = newParamSlots(layout, vals)
    check slots.getParamAt(0) == "v2"
    check slots.getParamAt(1) == "users"

  test "full flow: materialize preserves all values":
    let layout: ParamLayout = @["x", "y", "z"]
    let segs = @["a", "1", "b", "2", "c", "3"]
    let vals = extractSlotValues(layout, segs, "/:x/b/:y/c/:z")
    let slots = newParamSlots(layout, vals)
    let t = slots.materialize()
    check t["x"] == "1"
    check t["y"] == "2"
    check t["z"] == "3"
