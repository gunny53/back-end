# Ma trận tương thích – Plugin IntelliJ Nim

> Phase 0 deliverable: danh sách các tổ hợp IntelliJ Platform / JDK / Nim được hỗ trợ chính thức.

---

## 1. IntelliJ Platform versions

| IntelliJ Build | IDE version | Trạng thái hỗ trợ | Ghi chú |
|----------------|-------------|-------------------|---------|
| 243.x          | 2024.3.x    | ✅ Chính thức      | Minimum supported (Gradle `sinceBuild`) |
| 251.x          | 2025.1.x    | ✅ Chính thức      | |
| 252.x          | 2025.2.x    | ✅ Chính thức      | |
| 253.x          | 2025.3.x    | 🟡 Beta / CI test | `untilBuild` cập nhật trước mỗi release |
| < 243          | ≤ 2024.2    | ❌ Không hỗ trợ    | API Platform quá cũ |

**IDE được test**:
- IntelliJ IDEA Community & Ultimate
- PyCharm (via IntelliJ Platform)
- Rider / CLion / GoLand – không test, "best effort"

---

## 2. JDK versions

| JDK      | Trạng thái | Ghi chú |
|----------|-----------|---------|
| JDK 17   | ✅ Bắt buộc (minimum) | IntelliJ 2024.2+ yêu cầu JDK 17 |
| JDK 21   | ✅ Khuyến nghị | LTS, được CI test chính thức |
| JDK 11   | ❌ Không hỗ trợ | EOL, không tương thích IntelliJ 2024.3+ |
| JDK 23+  | 🟡 Experimental | Early Access; không đảm bảo ổn định |

> Plugin build target: **JVM 17** (`jvmTarget = "17"` trong `build.gradle.kts`).

---

## 3. Nim compiler versions

| Nim version | Trạng thái | Ghi chú |
|-------------|-----------|---------|
| 2.0.x       | ✅ Chính thức | Minimum Nim version |
| 2.2.x       | ✅ Chính thức | Khuyến nghị |
| 1.6.x       | 🟡 Best effort | Grammar cơ bản hoạt động; một số pragma mới không có |
| < 1.6       | ❌ Không hỗ trợ | |
| Devel/nightly | 🟡 CI smoke test | Báo cáo lỗi được chấp nhận |

> Khi tích hợp `nimsuggest` (Phase 2), version nimsuggest phải khớp với compiler đang dùng trong project.

---

## 4. OS / Architecture

| OS              | Arch       | Trạng thái |
|-----------------|-----------|-----------|
| macOS 13+       | x86_64, ARM64 | ✅ Chính thức |
| Ubuntu 22.04+   | x86_64     | ✅ Chính thức |
| Windows 10/11   | x86_64     | ✅ Chính thức |
| Linux ARM64     | ARM64      | 🟡 Best effort |
| FreeBSD         | any        | ❌ Không cam kết |

---

## 5. NimHTTP framework versions (cho adapter)

| NimHTTP   | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| HEAD/main | ✅ Chính thức | Adapter test chính |
| 0.x tagged | 🟡 Best effort | API có thể khác |

---

## 6. Chính sách CI

```
┌─────────────────────────────────────────────────────────┐
│  Matrix CI (GitHub Actions)                             │
│  OS:  ubuntu-latest, windows-latest, macos-latest       │
│  JDK: 17, 21                                            │
│  IDE: 2024.3 (sinceBuild), 2025.1, 2025.2               │
│  Nim: 2.0.x, 2.2.x                                      │
└─────────────────────────────────────────────────────────┘
```

Mỗi Pull Request phải pass toàn bộ matrix trước khi merge vào `main`.

---

## 7. Deprecation timeline

- Khi IntelliJ release version N, drop support cho version N-3 sau **6 tháng**.
- Khi Nim release major version, drop support cho major-2 sau **12 tháng**.

---

*Cập nhật lần cuối: 2026-04-08 | Xem thêm: [ADR-001](adr/ADR-001-parser-architecture.md)*
