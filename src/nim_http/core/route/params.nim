## Zero-alloc parameter binding — Phase D of the NIMAX refactor roadmap.
##
## Replaces the per-request ``Table[string, string]`` allocation used for
## path parameters with a slot-based value store keyed by a fixed layout
## that is shared across all requests for the same route.
##
## Design summary
## ==============
## - ``ParamLayout`` is a ``seq[string]`` holding the ordered parameter names
##   for one route template (e.g. ``@["userId", "postId"]``).  It is created
##   **once per route** at startup from the compile-time IR.
##
## - ``ParamSlots`` is a lightweight value object that combines a reference to
##   the shared ``ParamLayout`` with a per-request ``seq[string]`` of values.
##   Building a ``ParamSlots`` costs one ``seq[string]`` allocation vs. the
##   ``Table`` alloc + hash ops previously required.
##
## - ``materialize`` converts ``ParamSlots`` to ``TableRef[string, string]``
##   when legacy code (or reflection) needs map-style access.  It is
##   intentionally *not* called by the dispatcher hot-path.

import tables, strutils

# ---------------------------------------------------------------------------
# Types
# ---------------------------------------------------------------------------

type
  ParamLayout* = seq[string]
    ## Ordered list of path-parameter names for a route template.
    ## Shared across all requests for the same route.

  ParamSlots* = object
    ## Slot-based parameter store for a single request.
    ##
    ## ``layout`` references the route's ``ParamLayout`` (shared, set once at
    ## startup).  ``values`` holds the extracted values in the same order.
    ## No hash table is allocated; lookup by name is an O(n) scan over the
    ## (always tiny) layout sequence.
    layout*: ParamLayout
    values*: seq[string]

# ---------------------------------------------------------------------------
# Constructors
# ---------------------------------------------------------------------------

proc emptyParamSlots*(): ParamSlots =
  ## Returns a ``ParamSlots`` with no parameters.
  ParamSlots(layout: @[], values: @[])

proc newParamSlots*(layout: ParamLayout, values: seq[string]): ParamSlots =
  ## Creates a ``ParamSlots`` from an existing layout and extracted values.
  ## ``values.len`` must equal ``layout.len``; excess values are ignored and
  ## missing values default to empty string.
  let n = layout.len
  var vals = newSeq[string](n)
  for i in 0 ..< min(n, values.len):
    vals[i] = values[i]
  ParamSlots(layout: layout, values: vals)

# ---------------------------------------------------------------------------
# Slot operations
# ---------------------------------------------------------------------------

proc slotIndex*(layout: ParamLayout, name: string): int =
  ## Returns the slot index for *name* in *layout*, or ``-1`` when not found.
  for i, n in layout:
    if n == name:
      return i
  return -1

proc getParamAt*(slots: ParamSlots, idx: int): string =
  ## Returns the parameter value at slot position *idx*.  O(1).
  ## Returns an empty string when *idx* is out of range.
  if idx >= 0 and idx < slots.values.len:
    return slots.values[idx]
  return ""

proc getParam*(slots: ParamSlots, name: string): string =
  ## Returns the parameter value for *name* via slot-index scan.  O(n) on
  ## parameter count, which is always tiny (≤ 8) in real-world routes.
  ## Returns an empty string when *name* is not found.
  let idx = slotIndex(slots.layout, name)
  if idx >= 0:
    return getParamAt(slots, idx)
  return ""

proc isEmpty*(slots: ParamSlots): bool =
  ## Returns ``true`` when no parameters are bound in this ``ParamSlots``.
  slots.layout.len == 0

proc len*(slots: ParamSlots): int =
  ## Returns the number of parameter slots.
  slots.layout.len

# ---------------------------------------------------------------------------
# Lazy materialisation — only allocate Table when strictly required
# ---------------------------------------------------------------------------

proc materialize*(slots: ParamSlots): TableRef[string, string] =
  ## Converts ``slots`` to a ``TableRef[string, string]`` for backward-
  ## compatible access.  Call this only when legacy code needs map-style
  ## access; it allocates a new ``Table`` on each call.
  result = newTable[string, string]()
  for i, name in slots.layout:
    if i < slots.values.len:
      result[name] = slots.values[i]

# ---------------------------------------------------------------------------
# Extraction helper — used by the dispatcher hot-path
# ---------------------------------------------------------------------------

proc extractSlotValues*(names: ParamLayout, segs: seq[string],
                         rawPath: string): seq[string] =
  ## Extracts parameter values from the request path segments *segs* using
  ## the route template *rawPath*.  Returns values in the same order as
  ## *names*, ready to construct a ``ParamSlots``.
  ##
  ## This proc does **not** allocate a ``Table`` — it only produces a
  ## ``seq[string]`` of length ``names.len``.
  result = newSeq[string](names.len)
  let trimmed = rawPath.strip(chars = {'/'})
  if trimmed.len == 0 or names.len == 0:
    return
  var slot   = 0
  var segIdx = 0
  for seg in trimmed.split("/"):
    if seg.startsWith(":"):
      if slot < names.len and segIdx < segs.len:
        result[slot] = segs[segIdx]
      inc slot
    inc segIdx
