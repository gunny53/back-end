## Phase B unit tests — query-string parser and DI enhancements.

import unittest, tables

import nim_http/http/query
import nim_http/kernel/di

# ──────────────────────────────────────────────────────────────────────────────
# Query-string parser
# ──────────────────────────────────────────────────────────────────────────────

suite "phase b: query string parser":
  test "parses simple key=value pairs":
    let q = parseQueryString("foo=bar&baz=qux")
    check q.len == 2
    check q["foo"] == "bar"
    check q["baz"] == "qux"

  test "strips leading question mark":
    let q = parseQueryString("?x=1&y=2")
    check q.len == 2
    check q["x"] == "1"
    check q["y"] == "2"

  test "returns empty table for empty string":
    let q = parseQueryString("")
    check q.len == 0

  test "returns empty table for bare question mark":
    let q = parseQueryString("?")
    check q.len == 0

  test "handles key-only entry (no equals sign)":
    let q = parseQueryString("flag")
    check q.hasKey("flag")
    check q["flag"] == ""

  test "handles key with empty value":
    let q = parseQueryString("key=")
    check q.hasKey("key")
    check q["key"] == ""

  test "last value wins for duplicate keys":
    let q = parseQueryString("x=1&x=2&x=3")
    check q["x"] == "3"

  test "percent-decodes spaces":
    let q = parseQueryString("name=hello%20world")
    check q["name"] == "hello world"

  test "percent-decodes plus as space":
    let q = parseQueryString("msg=hello+world")
    check q["msg"] == "hello world"

  test "skips empty pair between consecutive ampersands":
    let q = parseQueryString("a=1&&b=2")
    check q.len == 2
    check q["a"] == "1"
    check q["b"] == "2"

  test "handles multiple params with mixed encoded chars":
    let q = parseQueryString("first=John&last=Doe&city=New%20York")
    check q.len == 3
    check q["first"] == "John"
    check q["last"] == "Doe"
    check q["city"] == "New York"

suite "phase b: queryFromUrl":
  test "extracts query string from full URL":
    let q = queryFromUrl("/api/users?page=1&limit=10")
    check q.len == 2
    check q["page"] == "1"
    check q["limit"] == "10"

  test "returns empty table when URL has no query string":
    let q = queryFromUrl("/api/users")
    check q.len == 0

  test "handles URL with only question mark":
    let q = queryFromUrl("/api/users?")
    check q.len == 0

  test "handles URL with encoded values":
    let q = queryFromUrl("/search?q=hello%20world&lang=en")
    check q["q"] == "hello world"
    check q["lang"] == "en"

# ──────────────────────────────────────────────────────────────────────────────
# DI enhancements: isRegistered + resolveAll
# ──────────────────────────────────────────────────────────────────────────────

type
  PhaseB_ServiceA = ref object of SingletonObj
  PhaseB_ServiceB = ref object of SingletonObj
  PhaseB_ServiceC = ref object of SingletonObj

suite "phase b: di isRegistered":
  test "unregistered type returns false":
    # PhaseB_ServiceC has not been registered at this point
    check not isRegistered(PhaseB_ServiceC)

  test "registered type returns true":
    register(PhaseB_ServiceA, Singleton,
      proc(): SingletonObj {.gcsafe.} = PhaseB_ServiceA())
    check isRegistered(PhaseB_ServiceA)

  test "isRegistered reflects legacy singletonRegistry":
    # Class macro populates singletonRegistry directly
    singletonRegistry[$PhaseB_ServiceB] = PhaseB_ServiceB()
    check isRegistered(PhaseB_ServiceB)

suite "phase b: di resolveAll":
  type PhaseB_Lazy = ref object of SingletonObj

  test "resolveAll eagerly creates singleton instances":
    register(PhaseB_Lazy, Singleton,
      proc(): SingletonObj {.gcsafe.} = PhaseB_Lazy())
    # Before resolveAll the instance is created at registration time (current
    # behaviour), so resolveAll is effectively a no-op here — but it must not
    # raise or corrupt state.
    resolveAll()
    let inst = inject(PhaseB_Lazy)
    check not inst.isNil

  test "resolveAll is idempotent":
    resolveAll()
    resolveAll()
    let inst = inject(PhaseB_Lazy)
    check not inst.isNil
