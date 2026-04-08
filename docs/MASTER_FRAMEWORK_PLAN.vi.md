# Master Plan 2026: Xây dựng NimHTTP thành framework production-grade kiểu NestJS / Spring Boot / .NET Core

> Mục tiêu: đưa NimHTTP từ “framework có đủ thành phần” sang “framework production hoàn chỉnh”, có kiến trúc module chuẩn, tốc độ top-tier, khả năng vận hành enterprise, và DX tốt cho team lớn.

## 1) Product Vision & North Star

### 1.1 Vision
Xây dựng một framework Nim có:
- API & module contract rõ ràng như NestJS/Spring Boot
- Hiệu năng native-level (low latency, low memory, fast startup)
- Chu kỳ release có kỷ luật (SemVer, migration, compatibility policy)
- Tooling đầy đủ (CLI, generators, benchmark, test harness)

### 1.2 North-Star Metrics (12 tháng)
- **Hello/JSON benchmark**: throughput tăng tối thiểu 2x so với baseline hiện tại.
- **CRUD API benchmark**: p95 latency giảm tối thiểu 35%.
- **Alloc/request**: giảm tối thiểu 40% trong hot path routing + middleware.
- **DX**: `nimhttp new` đến endpoint đầu tiên chạy được dưới 60 giây.
- **Release quality**: không có regression hiệu năng >5% nếu không có RFC phê duyệt.

---

## 2) Kiến trúc đích (Target Architecture)

## 2.1 Layer model chuẩn
1. **Kernel**: module graph, DI scopes, lifecycle.
2. **HTTP Runtime**: transport adapter, request/response abstraction, router engine.
3. **Pipeline**: middleware, guard, validation pipes, interceptors, exception filters.
4. **Platform**: config profiles, logging, metrics, tracing, health probes.
5. **Tooling**: CLI, scaffold, testing profile, benchmark profile, release automation.

## 2.2 Contract module kiểu enterprise
Mỗi module có cấu trúc thống nhất:
- `imports`
- `providers`
- `controllers`
- `exports`
- lifecycle hooks (`onModuleInit`, `onModuleDestroy`)

Rules bắt buộc:
- Không circular dependency (phát hiện compile-time nếu có thể, fallback runtime guard).
- Scope provider rõ ràng: `singleton`, `request`, `transient`.
- Có API override provider cho unit/integration tests.

## 2.3 Canonical request pipeline
`Request -> Middleware -> Guard -> Validation/Pipe -> Interceptor(before) -> Handler -> Interceptor(after) -> ExceptionFilter -> Response`

Nguyên tắc:
- Stage boundaries phải có contract input/output/error rõ.
- Chỉ bắt lỗi ở boundary có ý nghĩa chuyển đổi hoặc recover.
- Short-circuit chính thức cho auth fail/rate-limit/cache hit.

---

## 3) Roadmap triển khai theo giai đoạn

## Phase A (Tuần 0-6): Baseline & API Governance

### Deliverables
- Freeze public API cho `core/`, `kernel/`, `http/`, `platform/`, `pipeline/`.
- Tạo danh sách stable vs experimental API.
- Thiết lập benchmark baseline chính thức: hello/json/crud/validation.
- Thống nhất template RFC cho thay đổi runtime/hot path.

### Exit criteria
- Có API inventory + deprecation map.
- CI xuất artifact benchmark cho mọi PR vào nhánh chính.

## Phase B (Tuần 6-14): Runtime Performance Refactor

### Deliverables
- Router v2: trie matcher + precompiled param extraction.
- Startup pipeline planner: compile chain theo route trước khi nhận traffic.
- DI v2: typed token + scope resolver cache.
- Request context pooling + fast-path cho query/param parsing.

### Exit criteria
- Throughput tăng >=2x ở hello/json.
- Alloc/request giảm >=40% trên benchmark CRUD.

## Phase C (Tuần 14-22): Production Hardening

### Deliverables
- OpenTelemetry tracing + propagation theo request context.
- Metrics RED/USE + Prometheus exporter.
- Security defaults: secure headers, body limit, timeout, rate limiting presets.
- Liveness/readiness/startup probes + graceful shutdown đầy đủ.

### Exit criteria
- Pass toàn bộ production checklist.
- Có runbook vận hành và dashboard mẫu.

## Phase D (Tuần 22-36): Ecosystem & v1.0 GA

### Deliverables
- CLI đầy đủ: `new`, `generate`, `test`, `bench`, `release`.
- Starter templates: REST API, Auth/JWT, modular monolith.
- Release workflow: semver, changelog, signed artifacts, compatibility matrix.
- LTS policy + migration guide + deprecation tooling.

### Exit criteria
- Public v1.0 GA + docs production end-to-end.

---

## 4) Plan refactor bám sát cấu trúc hiện tại

## 4.1 `src/nim_http/core/route/*`

### Vấn đề
- Route matching còn nặng dynamic string scan.

### Refactor
- Tạo `CompiledRoute` tại startup.
- Dùng trie theo segment; static edge ưu tiên param edge.
- Precompute handler delegate table theo HTTP method.

### Kết quả kỳ vọng
- Lookup O(depth), giảm linear scan.
- Giảm parsing/alloc trong hot path.

## 4.2 `src/nim_http/core/middleware.nim` + `src/nim_http/pipeline/*`

### Vấn đề
- Merge middleware runtime mỗi request.

### Refactor
- Build `PipelinePlan` một lần tại boot.
- Chain execution theo index-based dispatcher (hạn chế closure churn).
- Dùng request-local shared metadata cho guard/interceptor/filter.

### Kết quả kỳ vọng
- Giảm alloc/request.
- Dễ đo latency theo từng stage pipeline.

## 4.3 `src/nim_http/core/di.nim` + `src/nim_http/kernel/di.nim`

### Vấn đề
- String-key lookup + cast runtime gây overhead.

### Refactor
- Typed token API + explicit resolver theo scope.
- Singleton resolution graph cache.
- Lỗi DI theo taxonomy rõ ràng: missing provider / cycle / scope violation.

### Kết quả kỳ vọng
- Lookup nhanh hơn.
- Error semantics rõ, dễ test hơn.

## 4.4 `src/nim_http/core/request.nim` + `src/nim_http/http/request.nim`

### Vấn đề
- Chưa có memory strategy nhất quán cho request scope.

### Refactor
- Thiết kế `RequestContext` immutable-by-default.
- Pool object/buffer cho params/query/headers copy.
- Fast-path parser cho ASCII common-case.

### Kết quả kỳ vọng
- Giảm pressure cho ARC/ORC.
- Tăng locality và giảm tail latency.

## 4.5 `src/nim_http/platform/*`

### Refactor
- Config profiles: `dev/test/staging/prod` + precedence rõ ràng.
- Structured logging + correlation/request ID.
- Tracing/metrics provider abstraction (cắm OTel/Prometheus dễ dàng).

## 4.6 `src/libs/*` và `src/apps/*`

### Refactor
- Tách app-level modules khỏi framework internals bằng clear interface.
- Chuẩn hóa boundary imports/exports để tránh coupling vòng.
- Tạo convention “thin controllers, rich services, explicit providers”.

---

## 5) Best-practice process để đạt “nhanh nhất” nhưng bền vững

## 5.1 Performance governance
- Mọi thay đổi hot path phải có perf hypothesis + benchmark evidence.
- Perf dashboard theo commit; cảnh báo regression tự động trong CI.
- Không tối ưu cảm tính; chỉ tối ưu điểm nghẽn đo được.

## 5.2 RFC workflow
- RFC ngắn gọn: problem, constraints, design, perf impact, migration.
- Review design trước code.
- Rollout bằng strangler pattern/feature flags cho thay đổi lớn.

## 5.3 Quality gates
- Unit tests: router matcher, DI resolver, pipeline planner.
- Integration tests: module graph + scope/lifecycle behavior.
- E2E tests: auth/error boundary/observability/lifecycle.
- Compatibility tests: deprecated API + migration path.

## 5.4 Release discipline
- SemVer nghiêm ngặt.
- Deprecation window tối thiểu 2 bản minor.
- MIGRATION_GUIDE bắt buộc cho mọi breaking/behavioral change.
- Nightly + RC trước GA để giảm rủi ro production.

---

## 6) Execution board 90 ngày (thực thi ngay)

### Sprint 1-2
- API surface audit + freeze.
- Thiết lập benchmark baseline + CI reporting.

### Sprint 3-4
- Router v2 data model + trie matcher.
- Tối ưu param extraction và method dispatch.

### Sprint 5-6
- Pipeline planner compile at startup.
- Loại bỏ middleware merge runtime.

### Sprint 7-8
- DI typed token + scope resolver cache.
- Module graph validation + cycle diagnostics.

### Sprint 9-10
- OTel traces + histogram metrics.
- Hardening defaults: timeout/body limit/rate limit/security headers.

### Sprint 11-12
- CLI release workflow + template apps.
- RC docs + migration checklist.

---

## 7) Definition of Done cho tuyên bố “nhanh gọn nhẹ nhất thế giới”

Chỉ tuyên bố khi đủ điều kiện:
1. Có benchmark công khai, tái lập được, so với các framework cùng lớp.
2. Duy trì p95/p99 tốt ổn định qua nhiều release liên tiếp.
3. Startup time + memory footprint ở nhóm dẫn đầu.
4. DX không hy sinh cho hiệu năng: học nhanh, scaffold nhanh, deploy rõ ràng.

Nếu bám đúng roadmap + governance ở trên, NimHTTP có khả năng đạt một vị thế rất mạnh: **framework Nim production-first, hiệu năng cao, kiến trúc enterprise rõ ràng nhưng vẫn lightweight**.
