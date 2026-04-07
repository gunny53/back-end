# NimHTTP Next: Production Framework Roadmap (NestJS / Spring Boot / .NET Core style)

> Mục tiêu: biến codebase hiện tại thành **framework production-grade**, có DX tốt, benchmark rõ ràng, release ổn định, và tốc độ/footprint thuộc nhóm tốt nhất thế giới cho Nim.

## 0) Đánh giá nhanh hiện trạng (dựa trên cấu trúc hiện có)

Codebase hiện đã có nền tảng quan trọng:

- `core/app.nim`: bootstrap + lifecycle.
- `core/controller*`, `core/route*`: decorator routing + binding.
- `core/di.nim`: DI cơ bản.
- `core/middleware.nim`, `core/interceptor.nim`, `core/guard.nim`: request pipeline.
- `core/config.nim`, `core/exception.nim`: config + error abstraction.
- `src/apps/*`, `src/libs/*`: tổ chức theo module nghiệp vụ.

Nhận định:

1. Đã có “shape” giống NestJS/Spring Boot nhưng còn thiếu “platform maturity” (test matrix, observability sâu, module system chuẩn hóa, release discipline).
2. Cần chuyển từ “feature-complete” sang “operationally-complete” để production thực chiến.
3. Cơ hội lớn nhất để “nhanh gọn nhẹ nhất”: giảm dynamic overhead trong pipeline + compile-time registration + zero-copy/data-locality.

---

## 1) Product Vision + North Star

### North star (12 tháng)

- **Developer Experience**: tạo project mới + chạy endpoint đầu tiên trong < 60 giây.
- **Performance**: p95 latency cạnh tranh với Go frameworks cho workload JSON API phổ biến.
- **Reliability**: có compatibility policy, migration guide, LTS branch.
- **Operability**: logs/metrics/traces chuẩn OpenTelemetry + health/readiness.

### Design principles

1. **Convention over configuration** (Nest/Spring style).
2. **Compile-time safety first** (Nim strength).
3. **Minimal runtime reflection**.
4. **Explicit module boundaries** (module graph rõ ràng).
5. **Production by default** (timeouts, limits, sane defaults bật sẵn).

---

## 2) Kiến trúc mục tiêu của framework

## 2.1 Layering

1. **Foundation Layer**
   - HTTP server adapter, event loop, memory/pool primitives.
2. **Application Kernel**
   - Module system, DI container, lifecycle hooks, config profiles.
3. **Transport Layer**
   - Router, middleware, guards, interceptors, exception filters, validation pipes.
4. **Platform Services**
   - Logging, metrics, tracing, cache abstraction, scheduler, task queue hooks.
5. **Developer Tooling**
   - CLI generate/build/test/release, scaffolding, codegen, docs generator.

## 2.2 Module model (Nest/Spring-like)

Mỗi module chuẩn:

- `controllers`
- `providers/services`
- `imports`
- `exports`
- `config`
- `onModuleInit/onModuleDestroy`

Tạo module graph compile-time + runtime validation:

- Detect circular dependency sớm.
- Scope policy rõ ràng: singleton/request/transient.
- Override provider cho test.

## 2.3 Request pipeline chuẩn hóa

`Incoming Request -> Middleware -> Guard -> Pipe/Validation -> Interceptor(before) -> Handler -> Interceptor(after) -> Exception Filter -> Response`

Quy tắc:

- Mỗi stage có contract rõ (input/output/error).
- Có short-circuit chính thức (guard fail, rate-limit, cached response).
- Context object immutable-by-default, mutable qua API kiểm soát.

---

## 3) Roadmap triển khai theo giai đoạn

## Phase A (0-4 tuần): Stabilize Core + Refactor nền

Mục tiêu: “khóa API nền” và chuẩn hóa package boundaries.

Deliverables:

1. **API Surface Audit**
   - Đánh dấu public/internal cho toàn bộ `nim_http/core/*`.
   - Tạo tài liệu “stability levels” (experimental/stable/deprecated).
2. **Refactor package layout**
   - `src/nim_http/core` -> tách thành:
     - `kernel/` (app, module, lifecycle, di)
     - `http/` (request, response, router)
     - `pipeline/` (middleware, guard, interceptor, pipes)
     - `platform/` (config, logging, observability)
3. **Unified error model**
   - 1 cây lỗi chuẩn + mapping HTTP/gRPC/event.
4. **Baseline benchmark harness**
   - Kịch bản hello/json/crud + load profile cố định.

Exit criteria:

- Core compile green.
- Public API list được freeze v0.x.
- Benchmark baseline được publish vào repo CI artifacts.

## Phase B (4-8 tuần): Module + DI nâng cấp production

Deliverables:

1. **Module descriptor chuẩn hóa** (imports/providers/exports/controllers).
2. **DI container v2**
   - Token typed.
   - Scope request tối ưu alloc.
   - Factory async + lifecycle hooks.
3. **Configuration profiles**
   - `dev/test/staging/prod` + override theo env.
4. **Validation & serialization layer**
   - DTO parsing nhanh, error message chuẩn hóa.

Exit criteria:

- E2E tests cho module graph + request scope.
- P95 không regress >5% so với baseline.

## Phase C (8-12 tuần): Observability + Security + Reliability

Deliverables:

1. **OpenTelemetry integration**
   - trace/span context propagation.
2. **Metrics**
   - request latency, error rate, saturation, queue depth.
3. **Security defaults**
   - secure headers, body limits, rate-limit policy presets.
4. **Readiness/Liveness probes**
   - endpoint chuẩn cho Kubernetes/systemd.

Exit criteria:

- Có dashboard mẫu + runbook incident.
- Security checklist pass cho OWASP API Top 10 hạng mục cốt lõi.

## Phase D (12-16 tuần): Tooling + Ecosystem + Release readiness

Deliverables:

1. **CLI**: `nimhttp new`, `generate module`, `generate resource`, `test`, `bench`.
2. **Starter templates**
   - REST API starter
   - Auth starter (JWT)
   - Microservice starter
3. **Release pipeline**
   - semantic versioning, changelog automation, signed artifacts.
4. **Compatibility policy**
   - deprecation window, migration docs, codemods nếu cần.

Exit criteria:

- v1.0 RC có migration guide + production checklist.

---

## 4) Kế hoạch refactor cụ thể dựa trên cấu trúc hiện tại

## 4.1 Đề xuất target tree

```text
src/nim_http/
  kernel/
    application.nim
    module.nim
    lifecycle.nim
    di/
      container.nim
      scope.nim
      token.nim
  http/
    server.nim
    request.nim
    response.nim
    routing/
      matcher.nim
      registry.nim
      delegate.nim
  pipeline/
    middleware.nim
    guard.nim
    interceptor.nim
    pipe.nim
    exception_filter.nim
  platform/
    config/
      loader.nim
      profile.nim
    observability/
      logger.nim
      metrics.nim
      tracing.nim
    security/
      headers.nim
      ratelimit.nim
  testing/
    test_application.nim
    test_client.nim
```

## 4.2 Nguyên tắc refactor “safe & fast”

1. **Strangler pattern**: giữ façade cũ (`core/*`) và forward sang module mới.
2. **Không breaking change đột ngột**: deprecate 2 minor versions trước khi xóa.
3. **Mỗi PR chỉ một trục thay đổi**: routing hoặc DI hoặc middleware, tránh PR “big bang”.
4. **Benchmark gate trong CI**: mọi refactor phải qua perf budget.

## 4.3 Refactor backlog ưu tiên cao

1. Router path matching tối ưu (precompiled route table).
2. Request context pooling + object reuse.
3. Serializer/deserializer fast path cho JSON hot routes.
4. DI resolution cache cho singleton/transient factories.
5. Error path hot optimization (tránh string concat dư thừa trên fast path).

---

## 5) “Quy trình chuẩn” để tạo framework nhanh gọn nhẹ nhất

## 5.1 Engineering operating system (EOS)

1. **RFC nhẹ** (1-2 trang) cho mọi capability lớn.
2. **Design review 30 phút** trước khi code.
3. **Perf contract** bắt buộc cho module nền.
4. **Definition of Done** gồm:
   - unit + integration + e2e
   - benchmark delta
   - docs + migration note

## 5.2 CI/CD chuẩn

- Matrix build: Linux/macOS/Windows, Nim stable + devel.
- Stages:
  1) lint/style
  2) unit tests
  3) integration/e2e
  4) benchmarks (nightly + PR sample)
  5) security scan + SBOM
  6) package publish

## 5.3 Testing pyramid

1. **Unit**: pure modules (matcher, serializer, di token).
2. **Integration**: pipeline ordering, module wiring, config profile.
3. **E2E**: app boot + real HTTP calls + error scenarios.
4. **Chaos-lite**: timeout, cancellation, high-concurrency burst.

## 5.4 Performance playbook

- Đặt budgets: cold start, RSS idle, p50/p95 latency, req/s.
- Dùng fixed workload + fixed hardware profile để so sánh.
- Mỗi optimization phải có before/after chart.
- Track regressions theo commit SHA.

---

## 6) Feature parity map với NestJS/Spring/.NET

## Core parity (bắt buộc cho v1.0)

- Module system hoàn chỉnh.
- DI scopes + lifecycle hooks.
- Middleware/Guard/Interceptor/Pipe/ExceptionFilter đầy đủ.
- Config profiles + secrets integration.
- Validation + serialization chuẩn hóa.
- Logging/metrics/tracing production-ready.

## Advanced parity (v1.1+)

- CQRS module.
- Event bus abstraction.
- Background jobs/scheduler.
- OpenAPI generation + client SDK generation.

---

## 7) Kế hoạch release production

## v0.8 (Internal beta)

- Freeze API core.
- Benchmarks + observability nền.
- Tài liệu migration từ core cũ.

## v0.9 (Public beta)

- CLI + starter templates.
- Security defaults bật sẵn.
- Tối thiểu 2 sample apps production-like.

## v1.0 (GA)

- Compatibility policy công bố chính thức.
- SLO guide + operation runbook.
- Long-term maintenance branch.

---

## 8) KPI đo thành công

1. Time-to-first-endpoint (TTFE) < 60s.
2. p95 latency giảm >= 20% so với baseline hiện tại ở JSON CRUD workload.
3. Memory RSS giảm >= 15% ở 1k concurrent keep-alive connections.
4. 0 critical vulnerabilities ở mỗi release gate.
5. 80%+ public API có docs + example + test coverage.

---

## 9) Kế hoạch thực thi 30 ngày đầu (actionable)

Tuần 1:

- Audit public API + annotate stable/experimental.
- Dựng benchmark harness + CI job nightly.

Tuần 2:

- Tách `kernel` + giữ compatibility façade cho `core/*`.
- Chuẩn hóa error contracts.

Tuần 3:

- DI v2 token typed + request scope tối ưu.
- Thêm integration tests cho module graph.

Tuần 4:

- Observability tối thiểu (structured log + metrics cơ bản).
- Public roadmap + v0.8 alpha release notes.

---

## 10) Kết luận

Nếu bám roadmap này, framework sẽ đi đúng quỹ đạo từ “đã có nhiều tính năng” sang “đủ trưởng thành để vận hành production ở quy mô thật”.

Điểm then chốt để đạt “nhanh gọn nhẹ nhất” không chỉ là viết code nhanh, mà là:

- tối ưu kiến trúc compile-time,
- kiểm soát perf bằng budget từ CI,
- giữ API ổn định để ecosystem tăng trưởng bền vững.
