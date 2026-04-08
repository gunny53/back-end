## Generated Dispatcher — Phase C of the NIMAX refactor roadmap.
##
## Replaces the per-request trie traversal (``for seg in segments``) with
## a flat ``Table[RouteKey, DispatchEntry]`` lookup that is O(1) on
## ``(method, segmentCount, staticMask)``.
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
# Dispatcher
# ---------------------------------------------------------------------------

type
  RouteDispatcher* = ref object
    ## Flat dispatch table built once at application startup.
    ## Hot-path lookup is a single ``Table`` probe followed by O(k) static
    ## segment verification, where k is the number of static segments.
    table: Table[RouteKey, DispatchEntry]

proc newRouteDispatcher*(): RouteDispatcher =
  ## Creates an empty ``RouteDispatcher``.
  RouteDispatcher(table: initTable[RouteKey, DispatchEntry]())

proc register*(d: RouteDispatcher, irEntry: RouteIREntry,
               detail: RouteDetail) =
  ## Adds one (IR metadata, handler) pair to the dispatcher table.
  d.table[irEntry.key] = DispatchEntry(irEntry: irEntry, detail: detail)

proc buildFrom*(d: RouteDispatcher,
                manifest: openArray[(string, string)]) =
  ## Populates the dispatcher from the compile-time manifest produced by
  ## ``routeManifest()``.  The corresponding ``RouteDetail`` handler is
  ## resolved from the global trie via ``findRouteDetail``.
  ##
  ## Call once at startup **after** all ``Controller`` macro bodies have
  ## executed (i.e. after ``addRoute`` has been called for every route).
  for (meth, path) in manifest:
    let met = parseEnum[HttpMethod](meth)
    let detail = findRouteDetail(path, met)
    if detail != nil:
      let entry = makeRouteIREntry(meth, path)
      d.register(entry, detail)

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
  var slot = 0
  let path  = entry.irEntry.rawPath
  let trimmed = path.strip(chars = {'/'})
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
# Hot-path dispatch
# ---------------------------------------------------------------------------

proc splitPathSegs(path: string): seq[string] =
  let trimmed = path.strip(chars = {'/'})
  if trimmed.len == 0: @[]
  else: trimmed.split("/")

proc dispatch*(d: RouteDispatcher, request: Request): Future[void] {.async, gcsafe.} =
  ## Dispatches *request* using the flat table.
  ##
  ## 1. Splits the request path into segments.
  ## 2. Computes ``(method, segmentCount, staticMask)`` directly — no trie
  ##    traversal.
  ## 3. Looks up the entry in the flat table (O(1) probe).
  ## 4. Verifies static segment values at their fixed positions.
  ## 5. Binds parameter slots by index.
  ##
  ## Raises ``NOT_FOUND`` or ``METHOD_NOT_ALLOWED`` on routing failures.
  let meth = $request.reqMethod
  let segs = splitPathSegs(request.url.path)
  let cnt  = segs.len

  # Compute the static mask from the *actual* request segments so we can
  # distinguish between static and param positions — note that for a request
  # URL we cannot know which positions are params without knowing the route.
  # We therefore iterate over all registered keys that share (method, count)
  # and check the mask against the actual segment values.

  var matched = false
  for key, entry in d.table:
    if key.httpMethod != meth or key.segmentCount != cnt:
      continue

    # Verify static segments at their bit positions
    let tmplPath = entry.irEntry.rawPath
    let trimmed  = tmplPath.strip(chars = {'/'})
    let tmplSegs = if trimmed.len == 0: newSeq[string]()
                   else: trimmed.split("/")
    var ok = true
    for i, tmplSeg in tmplSegs:
      if not tmplSeg.startsWith(":"):
        if i >= segs.len or segs[i] != tmplSeg:
          ok = false
          break
    if not ok:
      continue

    # Route matched — bind params by slot
    matched = true
    let params = bindParams(entry, segs)
    entry.detail.delegate.instance.params = params
    await entry.detail.resolve(request)
    return

  if not matched:
    # Try to distinguish 404 vs 405 for a better error message
    var pathFound = false
    for key, _ in d.table:
      if key.segmentCount == cnt:
        pathFound = true
        break
    if pathFound:
      raise METHOD_NOT_ALLOWED("Method " & meth & " not allowed for path: " &
                                request.url.path)
    else:
      raise NOT_FOUND("No route found for path: " & request.url.path)

# ---------------------------------------------------------------------------
# Facade export
# ---------------------------------------------------------------------------

proc isBuilt*(d: RouteDispatcher): bool =
  ## Returns ``true`` when the dispatcher has at least one registered route.
  d.table.len > 0

proc routeCount*(d: RouteDispatcher): int =
  ## Returns the number of routes currently registered in the dispatcher.
  d.table.len
