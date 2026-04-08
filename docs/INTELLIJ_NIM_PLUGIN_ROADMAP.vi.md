# Plan & Roadmap: Plugin JetBrains IntelliJ dành cho Nim (Framework-first)

> Mục tiêu: xây dựng một plugin IntelliJ chuyên sâu cho Nim với trải nghiệm lập trình tương đương các ngôn ngữ hạng A trong JetBrains, đồng thời tối ưu hỗ trợ framework (đặc biệt NimHTTP) ở mức “dùng được ngay trong dự án production”.

## 1) Tầm nhìn sản phẩm

### 1.1 North Star
- **Code nhanh hơn, đúng hơn**: completion/quick-fix/refactor thông minh cho Nim.
- **Framework-aware**: hiểu routing, module graph, DI patterns, lifecycle hooks của framework Nim.
- **Không khóa hệ sinh thái**: hỗ trợ Nim core trước, framework phổ biến sau, plugin architecture mở.

### 1.2 Persona chính
1. **Backend dev** dùng Nim + NimHTTP.
2. **Library maintainer** cần static analysis + refactor an toàn.
3. **Team lead** cần quality gates trong IDE (lint, diagnostics, test + run configs).

### 1.3 KPI 12 tháng
- Time-to-first-endpoint (trong IDE) < 5 phút.
- >= 80% lỗi cú pháp/phổ biến được bắt trước khi chạy `nim c`.
- Completion acceptance rate >= 35% ở file Nim.
- Startup indexing dự án tầm trung < 20 giây.
- Crash-free sessions >= 99.5%.

---

## 2) Phạm vi tính năng

## 2.1 Core language support (MVP bắt buộc)
1. **Syntax + parser PSI chuẩn Nim** (keywords, pragmas, macros cơ bản).
2. **Semantic highlighting** (types/symbol scopes/proc/iterator/template/macro).
3. **Go to definition / Find usages / Rename**.
4. **Completion** (identifier, imports, fields, proc signatures).
5. **On-the-fly diagnostics** (syntax, unresolved symbol, duplicate declarations).
6. **Formatter cơ bản** (indentation rules, style profile).

## 2.2 Developer workflow
1. **Run/Debug configurations** cho `nim c -r`, test files, project targets.
2. **Nimble integration**: install/update/deps script.
3. **Tool window**: build output parse thành clickable diagnostics.
4. **Quick fixes**: auto import, create proc/type stub, missing case branches.

## 2.3 Framework support (v1)
1. **Route intelligence** (điều hướng từ endpoint string sang handler).
2. **Controller/Module/Provider navigation** (nếu dự án dùng NimHTTP).
3. **Inspections**:
   - duplicate route,
   - invalid method/path pattern,
   - unresolved provider token,
   - vòng phụ thuộc module cơ bản.
4. **Code generation**: new controller/module/service templates.

## 2.4 Nâng cao (v2+)
- Structural search cho Nim AST patterns.
- Framework extension points cho plugin con (NimHTTP, Jester, Prologue...).
- Language Server bridge (nếu cần hybrid architecture).

---

## 3) Kiến trúc kỹ thuật đề xuất

## 3.1 Các module plugin
1. `nim-psi`: lexer/parser/PSI/stub index.
2. `nim-analysis`: symbol resolution, type inference mức vừa đủ, inspections.
3. `nim-ide`: completion, navigation, quick-fix, refactor.
4. `nim-runner`: run/debug/nimble/build integration.
5. `nim-framework-api`: contracts để framework adapters đăng ký model.
6. `nim-framework-nimhttp`: adapter cụ thể cho NimHTTP.

## 3.2 Thiết kế framework adapter
- Contract tối thiểu:
  - `discoverRoutes(project)`
  - `discoverModules(project)`
  - `resolveProvider(token, scope)`
  - `generateScaffold(kind, context)`
- Ưu tiên index incremental + cache invalidation theo file change.

## 3.3 Performance strategy
- Stub index cho declarations quan trọng.
- Resolve theo lazy phases (không full type-check mọi file).
- Debounce analysis + read actions ngắn.
- Sampling profiling mỗi mốc release.

---

## 4) Roadmap theo phase (12 tháng)

## Phase 0 (Tuần 1-2): Discovery & nền tảng
### Deliverables
- Product requirements + architecture decision records (ADR).
- Bộ benchmark dự án mẫu (small/medium/large Nim repos).
- Danh sách compatibility: IntelliJ versions, JDK, Nim versions.

### Exit criteria
- Freeze phạm vi MVP.
- Chốt kiến trúc parser (native PSI vs bridge từ compiler/LSP).

## Phase 1 (Tuần 3-8): Language MVP
### Deliverables
- Lexer/parser/PSI chạy ổn trên grammar Nim cốt lõi.
- Syntax highlighting + basic completion.
- Go to definition + Find usages (declaration-level).
- Basic diagnostics + quick-fix import.

### Exit criteria
- Mở/sửa/build được dự án Nim vừa mà không lỗi nghiêm trọng IDE.
- Internal dogfood bởi 3-5 dev.

## Phase 2 (Tuần 9-14): IDE Productivity
### Deliverables
- Rename refactor an toàn cho symbol phổ biến.
- Formatter v1 + style settings.
- Nimble tasks, run/debug configs, output parser.
- Test runner integration (single test/file).

### Exit criteria
- “Daily-driver” cho tác vụ viết code Nim cơ bản.

## Phase 3 (Tuần 15-22): Framework-first (NimHTTP)
### Deliverables
- Route map tool window.
- Navigation: route <-> handler <-> module/provider.
- Framework inspections + quick fixes.
- Scaffold generators: module/controller/service.

### Exit criteria
- Dev NimHTTP có thể tạo module mới + debug endpoint hoàn toàn trong IDE.

## Phase 4 (Tuần 23-30): Hardening & Ecosystem
### Deliverables
- Cải thiện incremental indexing + memory footprint.
- Telemetry ẩn danh (opt-in) cho hiệu năng & lỗi plugin.
- API cho framework adapters + tài liệu mở rộng.

### Exit criteria
- EAP cho cộng đồng rộng hơn, crash rate < 1% phiên.

## Phase 5 (Tuần 31-40): Beta -> GA
### Deliverables
- QA matrix đầy đủ (OS/JDK/IntelliJ/Nim versions).
- Marketplace listing + docs + migration notes.
- Support policy + issue triage SLA.

### Exit criteria
- GA 1.0 trên JetBrains Marketplace.

---

## 5) Backlog ưu tiên (MoSCoW)

## Must-have
- PSI ổn định, completion, navigation, rename cơ bản.
- Build/run/test integration.
- NimHTTP route/module awareness.

## Should-have
- Advanced inspections (DI cycle, dead provider).
- Refactor set mở rộng (extract proc, inline const).
- Debugger UX tốt hơn (watches, value renderer).

## Could-have
- Multi-framework pack (Jester/Prologue adapters).
- Intentions thông minh dựa trên project conventions.

## Won’t-have (v1)
- Full compiler-equivalent type checker trong IDE.
- Auto-fix cho mọi macro meta-programming phức tạp.

---

## 6) Team & vận hành

## 6.1 Team đề xuất
- 1 Tech Lead (IntelliJ Platform + architecture).
- 2 Plugin engineers (PSI/analysis/IDE features).
- 1 Nim domain engineer (compiler/framework semantics).
- 1 QA automation engineer.
- 1 DX writer/devrel part-time.

## 6.2 Quy trình
- Sprint 2 tuần, release train 4 tuần.
- Mỗi feature lớn bắt buộc có RFC + perf impact note.
- Canary channel cho internal users trước public EAP.

## 6.3 Chất lượng
- Unit tests cho parser/resolver/inspections.
- Integration tests với IntelliJ test framework.
- Snapshot tests cho diagnostics/completion.
- Perf regression suite theo bộ repo chuẩn.

---

## 7) Rủi ro chính & giảm thiểu

1. **Nim macro complexity** làm semantic analysis khó chính xác.
   - Giảm thiểu: hỗ trợ progressive accuracy + fallback diagnostics.
2. **Chi phí bảo trì theo version IntelliJ** cao.
   - Giảm thiểu: compatibility matrix + CI test theo nhiều IDE builds.
3. **Thiếu chuẩn framework metadata** (route/DI conventions khác nhau).
   - Giảm thiểu: framework adapter API + metadata annotations nhẹ.
4. **Hiệu năng indexing khi dự án lớn**.
   - Giảm thiểu: stub indexes, lazy resolve, profiling budget theo milestone.

---

## 8) Kế hoạch hỗ trợ framework “tối đa” nhưng có kiểm soát

- **Chiến lược 2 tầng**:
  1. Tầng chung: framework API (route/module/DI abstraction).
  2. Tầng riêng: adapters cho từng framework.
- **Ưu tiên thứ tự**:
  1. NimHTTP (vì nhu cầu backend cao và có module/DI rõ).
  2. Jester.
  3. Prologue.
- **Tiêu chí thêm framework mới**:
  - Có metadata/convention ổn định,
  - Có ít nhất N dự án cộng đồng dùng thực tế,
  - Có maintainer liên hệ để validate behavior.

---

## 9) Release plan đề xuất

- **0.1.0-alpha**: syntax + basic completion + navigation.
- **0.3.0-alpha**: rename/formatter/run-debug.
- **0.5.0-beta**: NimHTTP adapter v1 + route map.
- **0.8.0-rc**: hardening + perf tuning + QA matrix.
- **1.0.0**: GA trên Marketplace.

---

## 10) Checklist bắt đầu ngay (2 tuần đầu)

1. Khởi tạo project plugin (Gradle IntelliJ Plugin).
2. Tạo lexer/parser skeleton cho Nim cốt lõi.
3. Cắm syntax highlight + file type + icons.
4. Thiết lập test harness parser/PSI.
5. Chuẩn bị sample repos cho benchmark.
6. Viết ADR-001 (parser architecture) và ADR-002 (framework adapter API).
7. Thiết kế schema telemetry opt-in (nếu có).

---

## 11) Định nghĩa thành công của v1.0

- Dev Nim có thể làm việc hằng ngày trong IntelliJ mà không cần chuyển editor phụ.
- Dự án NimHTTP có khả năng điều hướng/inspect/generate ở mức production-ready.
- Plugin có lộ trình mở rộng framework rõ ràng, không phải viết lại lõi khi scale hệ sinh thái.
