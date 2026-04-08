## Generated Dispatcher — Phase C of the NIMAX refactor roadmap.
##
## Replaces the per-request trie traversal (``for seg in segments``) with a
## two-level dispatch table:
##
##   Level 1: O(1) probe on ``(httpMethod, segmentCount)``
##   Level 2: linear scan of the (typically tiny) bucket to verify static
##             segment values and select the matching route template.
##
## This eliminates the O(depth) trie walk and the per-request ``for seg in
## segments`` loop in the common case where each ``(method, count)`` bucket
## contains exactly one entry.
##
## Usage::
##
##   # At application startup, after all Controller macros have run:
##   var disp = newRouteDispatcher()
##   disp.buildFrom(routeManifest())
##
##   # In the hot request path, replace ``req.process`` with:
##   await disp.dispatch(req)

import asynchttpserver, asyncdispatch, tables, strutils
import ir
import detail
import ../exception

# ---------------------------------------------------------------------------
# Dispatch entry — associates IR metadata with its runtime handler
# ---------------------------------------------------------------------------

type
  DispatchEntry* = object
    ## Binds compile-time route IR metadata to the runtime ``RouteDetail``
    ## handler looked up from the trie once at startup.
    irEntry*:  RouteIREntry  ## compile-time metadata (paramNames, rawPath…)
    detail*:   RouteDetail   ## runtime handler (nil when not yet resolved)

# ---------------------------------------------------------------------------
# Two-level dispatch key
# ---------------------------------------------------------------------------

type
  DispatchKey = tuple
    ## First-level lookup key: method string + segment count.
    ## Within a bucket all entries share the same shape; static-segment
    ## verification happens inside the bucket scan (usually 1 entry).
    httpMethod:   string
    segmentCount: int

# ---------------------------------------------------------------------------
# Dispatcher
# ---------------------------------------------------------------------------

type
  RouteDispatcher* = ref object
    ## Two-level dispatch table built once at application startup.
    ##
    ## ``table[(method, segmentCount)]`` returns the bucket of entries that
    ## share that shape.  For the vast majority of APIs each bucket contains
    ## exactly one entry, making the overall lookup effectively O(1).
    table: Table[DispatchKey, seq[DispatchEntry]]

proc newRouteDispatcher*(): RouteDispatcher =
  ## Creates an empty ``RouteDispatcher``.
  RouteDispatcher(table: initTable[DispatchKey, seq[DispatchEntry]]())

proc register*(d: RouteDispatcher, irEntry: RouteIREntry,
               detail: RouteDetail) =
  ## Adds one ``(IR metadata, handler)`` pair to the dispatcher table.
  let dk = (httpMethod: irEntry.key.httpMethod,
            segmentCount: irEntry.key.segmentCount)
  d.table.mgetOrPut(dk, @[]).add(
    DispatchEntry(irEntry: irEntry, detail: detail))

proc buildFrom*(d: RouteDispatcher,
                manifest: openArray[(string, string)]) =
  ## Populates the dispatcher from the compile-time manifest produced by
  ## ``routeManifest()``.  The corresponding ``RouteDetail`` handler is
  ## resolved from the global trie via ``findRouteDetail``.
  ##
  ## Call once at startup **after** all ``Controller`` macro bodies have
  ## executed (i.e. after ``addRoute`` has been called for every route).
  for (meth, path) in manifest:
    let met    = parseEnum[HttpMethod](meth)
    let detail = findRouteDetail(path, met)
    if detail != nil:
      d.register(makeRouteIREntry(meth, path), detail)

# ---------------------------------------------------------------------------
# Slot-based parameter binding
# ---------------------------------------------------------------------------

proc bindParams(entry: DispatchEntry,
                segs: seq[string]): TableRef[string, string] =
  ## Binds path parameter values to their names using the fixed slot layout
  ## recorded in ``irEntry.paramNames``.  Slot index is determined by the
  ## position of parameter segments in the original path template — no
  ## dynamic name search is required.
  result = newTable[string, string]()
  var slot   = 0
  let trimmed = entry.irEntry.rawPath.strip(chars = {'/'})
  if trimmed.len == 0:
    return
  var segIdx = 0
  for seg in trimmed.split("/"):
    if seg.startsWith(":"):
      if slot < entry.irEntry.paramNames.len and segIdx < segs.len:
        result[entry.irEntry.paramNames[slot]] = segs[segIdx]
      inc slot
    inc segIdx

# ---------------------------------------------------------------------------
# Static-segment verification helper
# ---------------------------------------------------------------------------

proc staticSegmentsMatch(entry: DispatchEntry, segs: seq[string]): bool =
  ## Returns ``true`` when every static segment in *entry*'s template equals
  ## the corresponding segment in *segs*.
  let trimmed = entry.irEntry.rawPath.strip(chars = {'/'})
  if trimmed.len == 0:
    return segs.len == 0
  var i = 0
  for tmplSeg in trimmed.split("/"):
    if not tmplSeg.startsWith(":"):
      if i >= segs.len or segs[i] != tmplSeg:
        return false
    inc i
  return true

# ---------------------------------------------------------------------------
# Hot-path dispatch
# ---------------------------------------------------------------------------

proc splitPathSegs(path: string): seq[string] =
  let trimmed = path.strip(chars = {'/'})
  if trimmed.len == 0: @[]
  else: trimmed.split("/")

proc dispatch*(d: RouteDispatcher, request: Request): Future[void] {.async, gcsafe.} =
  ## Dispatches *request* using the two-level table.
  ##
  ## 1. Splits the request path into segments.
  ## 2. Probes the table with ``(method, segmentCount)`` — O(1).
  ## 3. Scans the (usually single-entry) bucket to verify static segments.
  ## 4. Binds parameter slots by index and invokes the handler.
  ##
  ## Raises ``NOT_FOUND`` or ``METHOD_NOT_ALLOWED`` on routing failures.
  let meth = $request.reqMethod
  let segs = splitPathSegs(request.url.path)
  let cnt  = segs.len
  let dk   = (httpMethod: meth, segmentCount: cnt)

  if d.table.hasKey(dk):
    let bucket = d.table[dk]
    for entry in bucket:
      if staticSegmentsMatch(entry, segs):
        let params = bindParams(entry, segs)
        entry.detail.delegate.instance.params = params
        await entry.detail.resolve(request)
        return
    # The (method, count) exists but no static pattern matched.
    # This should not normally occur for well-formed route sets; treat
    # as NOT_FOUND rather than METHOD_NOT_ALLOWED.
    raise NOT_FOUND("No route found for path: " & request.url.path)

  # No bucket for this (method, count).  Check whether the path shape
  # is registered under a *different* method to distinguish 404 from 405.
  for key, _ in d.table:
    if key.segmentCount == cnt:
      # There is at least one route with this segment count but for a
      # different method. Check if the static segments actually match.
      let anyBucket = d.table[key]
      for entry in anyBucket:
        if staticSegmentsMatch(entry, segs):
          raise METHOD_NOT_ALLOWED("Method " & meth &
                                   " not allowed for path: " &
                                   request.url.path)
  raise NOT_FOUND("No route found for path: " & request.url.path)

# ---------------------------------------------------------------------------
# Introspection helpers
# ---------------------------------------------------------------------------

proc isBuilt*(d: RouteDispatcher): bool =
  ## Returns ``true`` when the dispatcher has at least one registered route.
  d.table.len > 0

proc routeCount*(d: RouteDispatcher): int =
  ## Returns the total number of routes currently registered across all
  ## ``(method, segmentCount)`` buckets.
  for _, bucket in d.table:
    result += bucket.len

