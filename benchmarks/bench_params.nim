## Phase D benchmark — Table[string,string] allocation vs ParamSlots.
##
## Measures the allocation cost difference between the old approach
## (building a ``Table[string, string]`` per request) and the Phase-D
## approach (building a ``ParamSlots`` via ``extractSlotValues``).

import times, tables

import nim_http/core/route/params

const iterations = 50_000

# ── Fixture: three representative routes by param count ─────────────────

const noParamPath   = "/health/live"
const oneParamPath  = "/api/users/:id"
const twoParamPath  = "/api/users/:userId/posts/:postId"
const threeParamPath = "/api/orgs/:orgId/teams/:teamId/members/:memberId"

let noParamSegs    = @["api", "users"]
let oneParamSegs   = @["api", "users", "42"]
let twoParamSegs   = @["api", "users", "10", "posts", "20"]
let threeParamSegs = @["api", "orgs", "5", "teams", "12", "members", "99"]

let noParamLayout:    ParamLayout = @[]
let oneParamLayout:   ParamLayout = @["id"]
let twoParamLayout:   ParamLayout = @["userId", "postId"]
let threeParamLayout: ParamLayout = @["orgId", "teamId", "memberId"]

# ============================================================
# Baseline: Table[string, string] per request
# ============================================================

template benchTable(name: string, layout: ParamLayout,
                    segs: seq[string], path: string) =
  let t0 = cpuTime()
  for _ in 0 ..< iterations:
    var tbl = newTable[string, string]()
    var slot   = 0
    let trimmed = path.strip(chars = {'/'})
    if trimmed.len > 0:
      for seg in trimmed.split("/"):
        if seg.startsWith(":") and slot < layout.len:
          tbl[layout[slot]] = segs[slot + (segs.len - layout.len)]
          inc slot
    discard tbl
  let ms = (cpuTime() - t0) * 1_000
  stdout.writeLine "bench_params_table_" & name & "_ms=" & $ms

benchTable("0param", noParamLayout,    noParamSegs,    noParamPath)
benchTable("1param", oneParamLayout,   oneParamSegs,   oneParamPath)
benchTable("2param", twoParamLayout,   twoParamSegs,   twoParamPath)
benchTable("3param", threeParamLayout, threeParamSegs, threeParamPath)

# ============================================================
# Phase D: ParamSlots per request
# ============================================================

template benchSlots(name: string, layout: ParamLayout,
                    segs: seq[string], path: string) =
  let t0 = cpuTime()
  for _ in 0 ..< iterations:
    let vals  = extractSlotValues(layout, segs, path)
    let slots = newParamSlots(layout, vals)
    discard slots.len
  let ms = (cpuTime() - t0) * 1_000
  stdout.writeLine "bench_params_slots_" & name & "_ms=" & $ms

benchSlots("0param", noParamLayout,    noParamSegs,    noParamPath)
benchSlots("1param", oneParamLayout,   oneParamSegs,   oneParamPath)
benchSlots("2param", twoParamLayout,   twoParamSegs,   twoParamPath)
benchSlots("3param", threeParamLayout, threeParamSegs, threeParamPath)

# ============================================================
# Phase D: materialize (lazy Table) — rarely called path
# ============================================================

template benchMaterialize(name: string, layout: ParamLayout,
                           segs: seq[string], path: string) =
  let t0 = cpuTime()
  for _ in 0 ..< iterations:
    let vals  = extractSlotValues(layout, segs, path)
    let slots = newParamSlots(layout, vals)
    discard slots.materialize()
  let ms = (cpuTime() - t0) * 1_000
  stdout.writeLine "bench_params_materialize_" & name & "_ms=" & $ms

benchMaterialize("1param", oneParamLayout,   oneParamSegs,   oneParamPath)
benchMaterialize("2param", twoParamLayout,   twoParamSegs,   twoParamPath)
benchMaterialize("3param", threeParamLayout, threeParamSegs, threeParamPath)

stdout.writeLine "bench_params_iterations=" & $iterations
stdout.writeLine "bench_params_done=true"
