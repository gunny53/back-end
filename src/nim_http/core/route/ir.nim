## Route IR — compile-time route registry.
##
## Phase B of the NIMAX refactor roadmap.  Every route registered via the
## ``Controller`` macro also emits an entry into a compile-time
## ``CacheSeq``.  ``routeManifest`` then materialises that sequence as a
## seq literal, and ``buildRouteIndex`` converts it to a runtime lookup
## table keyed by ``RouteKey``.

import macros, macrocache, tables, strutils

# ---------------------------------------------------------------------------
# Compile-time IR cache
# ---------------------------------------------------------------------------

const routeIRCache* = CacheSeq("nim_http.route_ir_v1")
  ## Per-compilation accumulator for ``(httpMethod, path)`` pairs.
  ## Entries are added by ``addRouteIR`` during ``Controller`` macro
  ## expansion and consumed by ``routeManifest``.

# ---------------------------------------------------------------------------
# Key and entry types
# ---------------------------------------------------------------------------

type
  RouteKey* = tuple
    ## Composite lookup key derived from a route template at compile time.
    httpMethod:   string  ## "GET", "POST", …
    segmentCount: int     ## number of path segments
    staticMask:   uint64  ## bit i = 1 when segment i is a static literal

  RouteIREntry* = object
    ## Immutable snapshot of one route computed from its URL template.
    key*:        RouteKey
    rawPath*:    string       ## original template, e.g. "/users/:id/posts"
    paramNames*: seq[string]  ## ordered param-slot names (left to right)

# ---------------------------------------------------------------------------
# Pure helpers — usable at compile time and runtime
# ---------------------------------------------------------------------------

proc computeStaticMask*(path: string): uint64 =
  ## Returns a bitmask where bit *i* is ``1`` when segment *i* is a static
  ## literal and ``0`` when it is a named parameter (begins with ``:``)
  let trimmed = path.strip(chars = {'/'})
  if trimmed.len == 0:
    return 0u64
  var i = 0
  for seg in trimmed.split("/"):
    if not seg.startsWith(":"):
      result = result or (1u64 shl i)
    inc i

proc computeSegmentCount*(path: string): int =
  ## Returns the number of slash-delimited segments in *path*.
  let trimmed = path.strip(chars = {'/'})
  if trimmed.len == 0: 0
  else: trimmed.split("/").len

proc computeParamNames*(path: string): seq[string] =
  ## Returns the ordered list of parameter names (without the leading ``:``)
  ## found in *path*.
  let trimmed = path.strip(chars = {'/'})
  if trimmed.len == 0:
    return @[]
  for seg in trimmed.split("/"):
    if seg.startsWith(":"):
      result.add(seg[1..^1])

proc computeRouteKey*(httpMethod, path: string): RouteKey =
  ## Constructs the ``RouteKey`` for *httpMethod* and *path*.
  (httpMethod:   httpMethod,
   segmentCount: computeSegmentCount(path),
   staticMask:   computeStaticMask(path))

proc makeRouteIREntry*(httpMethod, path: string): RouteIREntry =
  ## Builds a full ``RouteIREntry`` for *httpMethod* and *path*.
  RouteIREntry(
    key:        computeRouteKey(httpMethod, path),
    rawPath:    path,
    paramNames: computeParamNames(path)
  )

# ---------------------------------------------------------------------------
# Compile-time macro: emit route into cache
# ---------------------------------------------------------------------------

macro addRouteIR*(httpMethod: static string, path: static string) =
  ## Records a ``(httpMethod, path)`` pair into the compile-time IR cache.
  ## Invoke once per route inside the ``Controller`` macro expansion
  ## *before* ``routeManifest`` is evaluated.
  routeIRCache.add(newLit((httpMethod, path)))

# ---------------------------------------------------------------------------
# Compile-time macro: materialise manifest as a seq literal
# ---------------------------------------------------------------------------

macro routeManifest*(): untyped =
  ## Returns the compile-time route manifest as a ``seq[(string, string)]``
  ## of ``(httpMethod, path)`` pairs collected via ``addRouteIR``.
  ##
  ## Typical usage::
  ##
  ##   const manifest = routeManifest()
  ##   let index = buildRouteIndex(manifest)
  let arr = nnkBracket.newTree()
  for item in routeIRCache:
    arr.add(item)
  result = quote do:
    @`arr`

# ---------------------------------------------------------------------------
# Runtime: build index from manifest
# ---------------------------------------------------------------------------

type
  RouteIndex* = Table[RouteKey, seq[RouteIREntry]]
    ## Groups ``RouteIREntry`` values by their ``RouteKey`` for O(1) lookup.

proc buildRouteIndex*(manifest: openArray[(string, string)]): RouteIndex =
  ## Converts a flat ``(method, path)`` manifest produced by
  ## ``routeManifest()`` into a ``RouteIndex``.  Duplicate keys append to
  ## the same bucket; call ``hasConflict`` to detect ambiguous routes.
  result = initTable[RouteKey, seq[RouteIREntry]]()
  for (meth, path) in manifest:
    let entry = makeRouteIREntry(meth, path)
    result.mgetOrPut(entry.key, @[]).add(entry)

proc hasConflict*(index: RouteIndex): bool =
  ## Returns ``true`` when any key maps to more than one entry, indicating
  ## an ambiguous route registration that should be reported to the user.
  for _, entries in index:
    if entries.len > 1:
      return true
  return false

proc listConflicts*(index: RouteIndex): seq[(RouteKey, seq[RouteIREntry])] =
  ## Returns every conflicting ``(key, entries)`` pair in *index*.
  for key, entries in index:
    if entries.len > 1:
      result.add((key, entries))
