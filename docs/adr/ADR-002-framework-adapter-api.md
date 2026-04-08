# ADR-002: Framework Adapter API

| Trường        | Giá trị                              |
|---------------|--------------------------------------|
| **ID**        | ADR-002                              |
| **Ngày**      | 2026-04-08                           |
| **Trạng thái** | Accepted                            |
| **Tác giả**   | Team Plugin IntelliJ Nim             |

---

## Bối cảnh

Plugin IntelliJ Nim hướng tới mục tiêu "framework-first": cung cấp route navigation, DI graph, scaffold generation, và inspections đặc thù cho từng framework Nim (NimHTTP, Jester, Prologue, ...).

Thay vì hardcode logic từng framework vào core plugin, cần một **Framework Adapter API** để:
1. Core plugin (`nim-ide`) không phụ thuộc vào bất kỳ framework cụ thể nào.
2. Mỗi framework có thể đăng ký adapter của mình (built-in hoặc plugin con).
3. API đủ ổn định để không breaking khi core evolve.

---

## Các lựa chọn đã xem xét

### Lựa chọn A: Extension Point của IntelliJ Platform

**Mô tả**: Định nghĩa IntelliJ `extensionPoint` trong `plugin.xml`, mỗi framework adapter implement interface và đăng ký qua XML.

```xml
<!-- plugin.xml -->
<extensionPoints>
  <extensionPoint name="nimFrameworkAdapter"
                  interface="com.nimhttp.ide.framework.NimFrameworkAdapter"/>
</extensionPoints>
```

**Ưu điểm**:
- Pattern chuẩn của IntelliJ Platform, quen thuộc với developers.
- Lazy loading: adapter chỉ load khi project sử dụng framework đó.
- Hỗ trợ third-party adapter dưới dạng plugin JetBrains độc lập.

**Nhược điểm**:
- Đòi hỏi boilerplate XML registration.
- API contract phải stable ngay từ sớm để không break adapters.

**Độ rủi ro**: Thấp – đây là pattern tiêu chuẩn.

---

### Lựa chọn B: Service Locator / Registry

**Mô tả**: Adapter tự đăng ký vào một `NimFrameworkRegistry` singleton khi plugin khởi tạo.

```kotlin
NimFrameworkRegistry.register(NimHttpAdapter())
```

**Ưu điểm**: Đơn giản, không cần XML.

**Nhược điểm**: Khó lazy load, không theo convention Platform, khó test.

---

### Lựa chọn C: Annotation Processor (compile-time)

**Mô tả**: Adapter được discover qua Java SPI hoặc annotation processing.

**Nhược điểm**: Không tương thích tốt với IntelliJ plugin classloading model.

---

## Quyết định

**Chọn Lựa chọn A (Extension Point)** làm cơ chế đăng ký adapter.

### Contract tối thiểu (v1 API)

```kotlin
/**
 * Module: nim-framework-api
 * Adapter đăng ký qua extensionPoint "nimFrameworkAdapter"
 */
interface NimFrameworkAdapter {

    /** Tên framework (hiển thị trong UI). */
    val frameworkName: String

    /** Phiên bản API mà adapter này tương thích. */
    val apiVersion: Int get() = 1

    /**
     * Kiểm tra project có dùng framework này không.
     * Trả về true nếu tìm thấy dấu hiệu (nimble deps, import pattern...).
     */
    fun isApplicable(project: Project): Boolean

    /**
     * Liệt kê toàn bộ routes được định nghĩa trong project.
     * Kết quả được cache bởi core; adapter không cần tự cache.
     */
    fun discoverRoutes(project: Project): List<NimRouteDescriptor>

    /**
     * Liệt kê toàn bộ modules (theo nghĩa framework, không phải Nim module).
     */
    fun discoverModules(project: Project): List<NimModuleDescriptor>

    /**
     * Resolve một provider token về PSI element định nghĩa nó.
     * Trả về null nếu không tìm thấy.
     */
    fun resolveProvider(token: String, scope: GlobalSearchScope): PsiElement?

    /**
     * Sinh code scaffold cho kind đã cho vào context.
     * Kind: "controller", "module", "service", "middleware"
     */
    fun generateScaffold(kind: String, context: NimScaffoldContext): NimScaffoldResult
}
```

### Data classes tối thiểu

```kotlin
data class NimRouteDescriptor(
    val method: String,          // "GET", "POST", ...
    val path: String,            // "/users/:id"
    val handlerElement: PsiElement,
    val moduleElement: PsiElement?,
    val tags: List<String> = emptyList()
)

data class NimModuleDescriptor(
    val name: String,
    val psiElement: PsiElement,
    val imports: List<String>,
    val providers: List<String>,
    val controllers: List<String>,
    val exports: List<String>
)

data class NimScaffoldContext(
    val project: Project,
    val targetDirectory: PsiDirectory,
    val name: String,
    val options: Map<String, String> = emptyMap()
)

data class NimScaffoldResult(
    val files: List<Pair<String, String>>,  // filename -> content
    val openAfterCreate: String? = null     // file to open in editor
)
```

### Versioning strategy

- API version bump khi có breaking change.
- Adapter khai báo `apiVersion` nó implement.
- Core hiển thị warning nếu adapter dùng version cũ hơn current - 1.

---

## Hệ quả

- **Tích cực**: Core plugin tách biệt hoàn toàn khỏi framework-specific logic; third-party adapters có thể publish độc lập lên JetBrains Marketplace.
- **Tiêu cực**: Phải maintain backward compatibility sau khi GA; API design cần review kỹ trước khi publish.
- **Action cần làm trước Phase 3**: Tổ chức RFC nội bộ về API shape, dogfood với NimHTTP adapter prototype để xác nhận đủ expressive.

---

## Tham khảo

- [IntelliJ Platform – Extension Points](https://plugins.jetbrains.com/docs/intellij/plugin-extension-points.html)
- [IntelliJ Platform – Plugin Dependencies](https://plugins.jetbrains.com/docs/intellij/plugin-dependencies.html)
- NimHTTP source: `src/nim_http/kernel/module.nim`, `src/nim_http/core/router.nim`
- Roadmap: `docs/INTELLIJ_NIM_PLUGIN_ROADMAP.vi.md` §3.2
