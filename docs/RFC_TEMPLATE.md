# RFC — [Short Title]

> **Fill in all sections before opening a PR.** Delete this line when done.

---

## Metadata

| Field | Value |
|-------|-------|
| **RFC ID** | RFC-XXXX |
| **Author(s)** | @username |
| **Date** | YYYY-MM-DD |
| **Status** | Draft / Under Review / Accepted / Rejected / Superseded |
| **Supersedes** | RFC-YYYY *(if applicable)* |
| **Related issues** | #123 |

---

## 1. Problem statement

*Describe the specific, measurable problem. Reference benchmark numbers or profiling data if this
touches a hot path.*

---

## 2. Constraints

*List non-negotiable constraints: backward-compatibility requirements, API surface limits,
platform or compiler constraints, and any hard performance bounds.*

---

## 3. Proposed design

*Describe the change in enough detail that a reviewer can implement it from this RFC alone.*

### 3.1 API surface changes

*List every public symbol that is added, renamed, changed in signature, or removed. Reference
`docs/API_INVENTORY.md` stability tiers.*

```
+ newFoo(bar: int): Foo        # new stable symbol
~ process(req: Request): void  # signature change (was: Future[void])
- legacyHelper()               # removed — use newFoo instead
```

### 3.2 Internal implementation sketch

*Pseudocode or prose sufficient to reason about correctness and performance.*

---

## 4. Performance impact

*For any change to a hot path (routing, DI resolution, middleware pipeline, request parsing),
fill in this section. Otherwise write "N/A — not a hot-path change".*

### 4.1 Hypothesis

*What specific metric do you expect to improve, and by how much? Example:*
> Route lookup O(n) → O(depth); expect ≥20 % throughput increase on hello benchmark.

### 4.2 Benchmark evidence

*Paste before/after numbers from `benchmarks/bench_routing.nim`,
`benchmarks/bench_pipeline.nim`, `benchmarks/bench_di.nim`, or `benchmarks/bench_hello.nim`.*

```
# Before
bench_routing_iterations=1000
bench_routing_duration_ms=12.3

# After
bench_routing_iterations=1000
bench_routing_duration_ms=7.1
```

### 4.3 Regression risk

*Identify any benchmarks that might regress and why they are acceptable.*

---

## 5. Migration plan

*Describe how existing consumers of the changed API should update their code.*

- If symbols are renamed: provide a find-and-replace guide.
- If behavior changes: describe the old vs new behavior and the transition period.
- Add entries to `docs/MIGRATION_GUIDE.md` as part of this RFC's implementing PR.

---

## 6. Alternatives considered

*List at least one alternative design and why it was rejected.*

---

## 7. Open questions

*List unresolved design questions that reviewers should focus on.*

---

## 8. Checklist (author)

- [ ] `docs/API_INVENTORY.md` updated (stability tier set / deprecation row added)
- [ ] `docs/MIGRATION_GUIDE.md` updated (if breaking or behavioral change)
- [ ] Benchmark numbers attached in §4
- [ ] Tests added or updated
- [ ] No regressions > 5 % without explicit acceptance in §4.3
