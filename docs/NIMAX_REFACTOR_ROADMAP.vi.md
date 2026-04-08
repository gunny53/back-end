# Đánh giá hiện trạng & lộ trình refactor Nimax (định hướng nhanh-gọn-nhẹ)

## 1) Đánh giá framework đã triển khai hiện tại

### Điểm tốt
- Kiến trúc đã tách lớp khá rõ (`kernel`, `http`, `pipeline`, `platform`, `tooling`).
- Router hiện tại dùng cây segment (`RouteNode`) thay vì linear scan toàn bộ route.
- Có sẵn CLI scaffold và benchmark cơ bản để đo tác động khi refactor.

### Điểm nghẽn so với mục tiêu “nhanh nhất”
1. **Đăng ký route còn runtime mutable**: route được `addRoute` khi app khởi động.
2. **Match route vẫn phải duyệt segment theo vòng lặp mỗi request** (`for seg in segments`).
3. **Param extraction còn dynamic** (map theo tên mỗi request).
4. **Chưa có compile-time index route** để tạo dispatch trực tiếp theo method + shape path.

---

## 2) North Star cho router

Mục tiêu bắt buộc:
- **Compile-time route indexing**.
- **Runtime O(1) dispatch path class** (không loop quét bảng route).
- **Không cấp phát động cho static routes trong hot path**.
- **Param routes dùng layout cố định (slot-based)** thay vì map động.

---

## 3) Lộ trình refactor đề xuất

## Phase A — Rebrand & Compatibility (1-2 tuần)
- Đổi brand runtime/CLI sang `nimax`.
- Giữ alias `nimhttp` để không phá dự án hiện hữu.
- Chuẩn hoá docs: lệnh chính là `nimax`.

**Exit criteria**
- `nimax` hoạt động đầy đủ.
- `nimhttp` vẫn chạy tương thích.

## Phase B — Route IR & Compile-time Registry (2-4 tuần)
- Tạo `RouteIR` bất biến từ macro controller tại compile-time.
- Chuẩn hóa metadata: method, static segments, param slots, handler symbol.
- Sinh bảng index theo `(method, segmentCount, staticMask)`.

**Exit criteria**
- Build artifact có route manifest sinh tại compile-time.
- Không còn phụ thuộc vào `addRoute` runtime cho route mới.

## Phase C — Generated Dispatcher (4-8 tuần)
- Sinh mã dispatch bằng macro/template:
  - Static route: nhảy trực tiếp tới handler branch.
  - Param route: parse theo slot index cố định.
- Thay `for seg in segments` bằng dispatcher generated theo từng method.

**Exit criteria**
- Hot path route lookup không còn loop scan route table.
- Benchmark `bench_routing` cải thiện rõ rệt so với baseline.

## Phase D — Zero-alloc Parameter Binding (8-10 tuần)
- Bỏ `Table[string, string]` cho params trong hot path.
- Dùng struct/tuple slot có mapping compile-time từ tên tham số -> chỉ số.
- Chỉ materialize map khi handler thật sự yêu cầu reflection/path-by-name.

**Exit criteria**
- Giảm alloc/request đáng kể ở benchmark route tham số.

## Phase E — Hardening (10-12 tuần)
- Thêm property tests cho conflict route và precedence.
- Thêm benchmark gate trong CI (route/static/param/mixed).
- Freeze API router v1 (`nim_http/http/routing` hoặc namespace mới sau rebrand).

---

## 4) Thiết kế router compile-time indexing (mục tiêu kỹ thuật)

## 4.1 Compile-time dữ liệu
- `RouteKey = (HttpMethod, segmentCount, staticMask, firstStaticHash)`
- `RouteEntry = (normalizedPath, paramNames, handlerProc, guardPlan, interceptorPlan)`

## 4.2 Dispatcher strategy
- Tier 1: switch theo method.
- Tier 2: switch theo `segmentCount`.
- Tier 3: kiểm tra nhanh static positions (không duyệt toàn bộ registry).
- Tier 4: bind param slot và invoke delegate.

## 4.3 Conflict handling
- Detect conflict ngay compile-time:
  - trùng method + path template.
  - ambiguity static vs param cùng mức ưu tiên.
- Build fail sớm với message rõ ràng.

---

## 5) Kế hoạch đổi tên `nimhttp`, `nimash` sang `nimax`

1. **CLI/Binary**: chọn `nimax` là canonical command.
2. **Backward compatibility**: giữ `nimhttp` alias ít nhất 2 minor versions.
3. **Package naming**:
   - Ngắn hạn: giữ `nim_http` module path để tránh breaking change lớn.
   - Trung hạn: thêm facade namespace `nimax/*` rồi deprecate dần `nim_http/*`.
4. **Telemetry metrics prefix**:
   - Hỗ trợ cả `nimhttp_*` và `nimax_*` trong 1 chu kỳ chuyển đổi.
5. **Docs & generators**: toàn bộ starter/generator sinh command và branding theo `nimax`.

---

## 6) KPI đo thành công

- Routing throughput tăng >= 2x trong `bench_routing`.
- p95 latency route param giảm >= 35%.
- alloc/request giảm >= 40% ở endpoint có params + guard.
- 100% route conflict quan trọng bị bắt ở compile-time.

