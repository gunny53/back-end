# Master Plan & Roadmap NimHTTP Production Framework (NestJS / Spring Boot / .NET Core style)

> Mục tiêu: xây dựng NimHTTP thành **production-grade framework** có DX tốt, kiến trúc module rõ ràng, hiệu năng top-tier, release discipline chuẩn enterprise, nhưng vẫn giữ triết lý **nhanh + gọn + nhẹ**.

**Skills đang áp dụng cho kế hoạch này**
- `nim-api-design`: chuẩn hóa public contracts và boundaries.
- `nim-code-organization`: tái tổ chức modules theo ownership rõ ràng.
- `nim-error-handling`: quy hoạch chiến lược lỗi theo boundary/pipeline.

---

## 1) Đánh giá hiện trạng từ codebase hiện tại

### 1.1 Điểm mạnh đã có
- Đã có shape framework hiện đại: `kernel`, `core`, `pipeline`, `http`, `platform`, `tooling`.
- Đã có request pipeline primitives: middleware/guard/interceptor.
- Đã có decorator routing + controller binding.
- Đã có CLI scaffold và một số test định hướng kiến trúc.

### 1.2 Điểm nghẽn chính (cần refactor để đạt “nhanh nhất”)
1. **Routing hot path còn linear scan**
   - Matching route theo kiểu duyệt tuần tự, chưa pre-compile trie/segment index.
2. **Middleware execute có merge/copy runtime mỗi request**
   - Tạo danh sách middleware tổng hợp theo route ngay lúc xử lý request gây alloc dư thừa.
3. **DI container còn string-key và lookup dynamic**
   - Chi phí hash + cast runtime cao; khó tối ưu compile-time.
4. **Request scope chưa có memory strategy rõ ràng**
   - Chưa chuẩn hóa object reuse/pool cho context tần suất cao.
5. **Observability còn rời rạc**
   - Thiếu latency histogram/tracing propagation chuẩn OpenTelemetry.
6. **Release engineering chưa “framework-grade”**
   - Cần semver discipline, benchmark gate, compatibility/LTS workflow chặt chẽ.

---

## 2) North Star 12 tháng

### Product KPI
- **DX**: `nimhttp new` -> first endpoint chạy < 60s.
- **Performance**: p95 latency cạnh tranh nhóm đầu cho JSON API phổ biến.
- **Reliability**: release ổn định, migration không đau, policy backward-compat rõ ràng.
- **Operability**: logs/metrics/traces/probes bật sẵn cho production.

### Engineering KPI
- Startup time giảm >= 30% so với baseline hiện tại.
- Alloc/request giảm >= 40% ở benchmark CRUD JSON.
- Throughput tăng >= 2x ở hello/json benchmark.
- Regression perf gate: PR không được giảm >5% khi không có RFC chấp thuận.

---

## 3) Kiến trúc target (v1.0)

## 3.1 Layer chuẩn
1. **Kernel Layer**: app lifecycle, module graph, DI scopes.
2. **HTTP Layer**: server adapter, request/response, routing engine.
3. **Pipeline Layer**: middleware, guards, pipes/validation, interceptors, exception filters.
4. **Platform Layer**: config profiles, logging, tracing, metrics, health/readiness.
5. **Tooling Layer**: CLI, generators, testing harness, benchmark harness, release scripts.

## 3.2 Module contract giống Nest/Spring/.NET
Mỗi module có 5 nhóm rõ ràng:
- `imports`
- `providers`
- `controllers`
- `exports`
- lifecycle hooks: `onModuleInit`, `onModuleDestroy`

Rules:
- Cấm circular dependency ở compile-time nếu detect được, fallback runtime guard nếu không detect được.
- Scope rõ ràng: `singleton`, `request`, `transient`.
- Provider override có API chính thức cho unit/integration test.

## 3.3 Request pipeline canonical
`Request -> Middleware -> Guard -> Pipe/Validation -> Interceptor(before) -> Handler -> Interceptor(after) -> ExceptionFilter -> Response`

Rules:
- Stage contract rõ input/output/error.
- Chỉ catch lỗi ở boundary có thể recover/translate.
- Có short-circuit chính thức (auth fail/rate limit/cache hit).

---

## 4) Roadmap triển khai theo quý

## Q1 (0-8 tuần): Stabilize Core + Freeze Public API

### Deliverables
1. Audit toàn bộ export surface (`core/*`, `kernel/*`, `http/*`, `pipeline/*`, `platform/*`).
2. Tách rõ stable vs experimental API.
3. Tạo façade compatibility cho API cũ (deprecate có lộ trình).
4. Thiết lập benchmark baseline chính thức (hello/json/crud/validation).

### Exit Criteria
- Public API list được freeze cho v0.9.
- Có báo cáo baseline + artifact CI.

## Q2 (8-16 tuần): High-performance Runtime

### Deliverables
1. **Router v2**: segment trie + precompiled param extraction.
2. **Pipeline planner**: compile middleware chain theo route tại startup (không merge runtime).
3. **DI v2**: typed tokens, giảm string-key overhead ở hot path.
4. **Request context pooling**: object reuse + memory locality tối ưu ARC/ORC.

### Exit Criteria
- Throughput tăng >= 2x trên benchmark hello/json.
- p95 CRUD giảm >= 35%.

## Q3 (16-24 tuần): Production Hardening

### Deliverables
1. OpenTelemetry tracing + context propagation.
2. Metrics chuẩn RED/USE + Prometheus exporter.
3. Security defaults: secure headers, body limit, timeout, rate-limit presets.
4. Readiness/liveness/startup probes + graceful shutdown chuẩn orchestration.

### Exit Criteria
- Production checklist pass.
- Dashboard + runbook incident có sẵn.

## Q4 (24-36 tuần): Ecosystem + v1.0 GA

### Deliverables
1. CLI hoàn chỉnh: `new/generate/test/bench/release`.
2. Starter kits: REST, Auth (JWT), Background worker, Modular monolith.
3. Release automation: semver, changelog, signed artifact, compatibility matrix.
4. LTS policy + migration guide + deprecation tooling.

### Exit Criteria
- v1.0 GA và tài liệu production end-to-end.

---

## 5) Refactor plan chi tiết theo modules/features/platform/libs hiện có

## 5.1 `src/nim_http/core/route/*` -> Router Engine v2

### Hiện tại
- Parse/match route còn nặng dynamic string operations.

### Refactor
1. Chuẩn hóa route thành `CompiledRoute` tại startup.
2. Dùng segment trie:
   - static edges ưu tiên trước param edges.
   - lưu param slots thay vì map string cho từng request.
3. Sinh delegate table cố định theo HTTP method.

### Kết quả mong đợi
- O(depth) lookup thay vì linear scan.
- Giảm allocations/path parsing ở runtime.

## 5.2 `src/nim_http/core/middleware.nim` + `pipeline/*`

### Hiện tại
- Hợp nhất middleware global + route-specific ngay mỗi request.

### Refactor
1. Build `PipelinePlan` cho từng route tại boot.
2. Chain `next` theo kiểu iterative index (tránh closure churn không cần thiết).
3. Chuẩn hóa request-local context để guards/interceptors chia sẻ metadata.

### Kết quả mong đợi
- Giảm alloc/request.
- Dễ quan sát latency theo từng stage.

## 5.3 `src/nim_http/core/di.nim` + `kernel/di.nim`

### Hiện tại
- String keys + cast runtime.

### Refactor
1. Typed token API (generic token object).
2. Tách resolver theo scope (singleton/request/transient).
3. Cache resolution graph cho singleton.
4. Boundary error chuẩn: provider missing/cycle/scope violation.

### Kết quả mong đợi
- Lookup nhanh hơn, lỗi rõ hơn, testability tốt hơn.

## 5.4 `src/nim_http/core/request.nim` + `http/request.nim`

### Refactor
1. Định nghĩa `RequestContext` gọn, immutable-by-default.
2. Pool object cho các thành phần có tần suất cao (headers map/params buffer).
3. Tối ưu parser query/params theo fast path ASCII.

## 5.5 `src/nim_http/platform/*`

### Refactor
1. Config profile loader: `dev/test/staging/prod` + precedence rõ.
2. Logging structured JSON + correlation IDs.
3. Metrics exporter + tracing provider plugin.

## 5.6 `src/libs/*`

### Refactor
- Tách contracts của libs khỏi framework core.
- Áp dụng interface nhỏ + explicit imports/exports để tránh coupling vòng.

---

## 6) Best-practice process để đạt tốc độ cao nhất một cách bền vững

## 6.1 Performance governance
1. Mọi feature vào hot path phải có **perf contract**.
2. PR bắt buộc kèm benchmark before/after cho module liên quan.
3. Duy trì perf dashboard theo commit.
4. Chỉ tối ưu “measured bottleneck”, không tối ưu cảm tính.

## 6.2 RFC + delivery workflow
1. RFC ngắn (problem, constraints, design, perf impact, migration).
2. Design review trước khi code.
3. Triển khai theo strangler pattern, không big-bang rewrite.
4. Rollout bằng feature flags nếu ảnh hưởng lớn runtime.

## 6.3 Quality gates
- Unit tests cho matcher/DI/pipeline planner.
- Integration tests cho module graph + scope behavior.
- E2E tests cho lifecycle + error boundary + observability.
- Compatibility tests cho deprecated API.

## 6.4 Release discipline
- SemVer nghiêm ngặt.
- Deprecation window tối thiểu 2 minor.
- MIGRATION_GUIDE cập nhật theo release.
- Nightly + RC channel trước GA.

---

## 7) Execution board 90 ngày đầu (thực thi ngay)

### Sprint 1-2
- Freeze public API + benchmark baseline.
- Thiết kế Router v2 data model.

### Sprint 3-4
- Implement trie matcher + method dispatch table.
- Đo và tối ưu alloc/request.

### Sprint 5-6
- Pipeline planner startup compile.
- Refactor middleware chain không merge runtime.

### Sprint 7-8
- DI typed token + scope resolver.
- Bổ sung module graph validation.

### Sprint 9-10
- OTel traces + latency histogram.
- Production hardening defaults.

### Sprint 11-12
- CLI workflows + release automation + RC docs.

---

## 8) Định nghĩa “nhanh gọn nhẹ nhất thế giới” (thực tế, đo được)

Không tuyên bố bằng slogan; chỉ tuyên bố bằng số liệu:
- Top-tier p95/p99 trong benchmark công khai.
- Binary footprint nhỏ, startup nhanh, memory thấp.
- Tốc độ phát triển cao nhờ module contracts rõ và CLI tốt.

Nếu giữ đúng roadmap + governance ở trên, NimHTTP có khả năng trở thành framework Nim hiện đại mạnh nhất cho production workloads.
