# ADR-001: Kiến trúc Parser cho Plugin IntelliJ Nim

| Trường        | Giá trị                              |
|---------------|--------------------------------------|
| **ID**        | ADR-001                              |
| **Ngày**      | 2026-04-08                           |
| **Trạng thái** | Accepted                            |
| **Tác giả**   | Team Plugin IntelliJ Nim             |

---

## Bối cảnh

Plugin IntelliJ cho Nim cần phân tích cú pháp (parse) mã nguồn Nim để cung cấp các tính năng như syntax highlighting, completion, navigation, và diagnostics. Có ba hướng tiếp cận chính:

1. **Native PSI** – Viết lexer/parser tùy chỉnh tích hợp trực tiếp vào IntelliJ Platform PSI.
2. **LSP Bridge** – Sử dụng Language Server Protocol (nimlangserver / nimsuggest) thông qua plugin LSP4IJ của JetBrains.
3. **Compiler Integration** – Gọi trực tiếp `nimsuggest` như một daemon cho suggest/type-check.

---

## Các lựa chọn đã xem xét

### Lựa chọn A: Native PSI (JFlex + GrammarKit)

**Mô tả**: Định nghĩa grammar Nim bằng BNF (`nim.bnf`), dùng GrammarKit sinh PSI classes, JFlex sinh lexer. Toàn bộ tree nằm trong bộ nhớ của IntelliJ.

**Ưu điểm**:
- Tích hợp sâu nhất với Platform (stub indexes, rename, find usages).
- Hiệu năng tốt: incremental parse, không fork process ngoài.
- Full control over PSI tree structure và error recovery.
- Hỗ trợ offline, không phụ thuộc tool ngoài.

**Nhược điểm**:
- Tốn công xây dựng: grammar Nim phức tạp (macros, template, pragma, indentation-sensitive).
- Phải bảo trì grammar song song với compiler khi Nim cập nhật.
- Semantic accuracy thấp hơn compiler thực sự với macro expansion.

**Độ rủi ro**: Trung bình – đây là con đường nhiều IntelliJ plugin ngôn ngữ đã đi (Rust, Go, Kotlin before official).

---

### Lựa chọn B: LSP Bridge (LSP4IJ)

**Mô tả**: Tận dụng plugin [LSP4IJ](https://github.com/redhat-developer/lsp4ij) của Red Hat/JetBrains. Khởi động `nimlangserver` và map kết quả LSP vào Platform features.

**Ưu điểm**:
- Reuse toàn bộ semantic từ `nimlangserver` (type-check, hover, completion).
- Ít code parse tùy chỉnh; nhanh chóng có baseline.
- Cập nhật language spec tự động khi nimlangserver cập nhật.

**Nhược điểm**:
- Phụ thuộc binary ngoài (`nimlangserver` phải cài sẵn).
- Tích hợp PSI nông: stub index, find usages toàn codebase, inline rename khó làm đầy đủ.
- Độ trễ cao hơn (IPC round-trip cho mọi operation).
- Framework-aware features (route map, DI graph) rất khó build trên LSP abstraction.

**Độ rủi ro**: Thấp ban đầu, cao về lâu dài cho framework-first vision.

---

### Lựa chọn C: Hybrid (PSI Skeleton + nimsuggest daemon)

**Mô tả**: Native PSI cho cấu trúc cú pháp và syntax highlighting; gọi `nimsuggest` qua socket/stdin để lấy type info và semantic completion.

**Ưu điểm**:
- PSI đầy đủ cho navigation/refactor/stub index.
- Semantic accuracy từ compiler thực sự cho completion/diagnostics.
- Đã được chứng minh bởi plugin Nim Community Edition (phiên bản cũ).

**Nhược điểm**:
- Quản lý lifecycle của nimsuggest daemon (restart khi crash, timeout).
- Đồng bộ hóa PSI state với nimsuggest state phức tạp.
- Phụ thuộc `nimsuggest` được cài đúng version.

---

## Quyết định

**Chọn Lựa chọn A (Native PSI)** làm kiến trúc chính, với kế hoạch tích hợp `nimsuggest` ở Phase 2 cho semantic completion.

### Lý do

1. **Framework-first vision đòi hỏi PSI sâu**: Route map, DI graph visualization, scaffold generation – tất cả cần đọc/ghi PSI trực tiếp. LSP bridge không đủ.
2. **Hiệu năng offline**: Developer không cần cài tool ngoài để dùng syntax highlight, navigation cơ bản.
3. **Ecosystem precedent**: JetBrains Rust, Go, Kotlin plugin đều đi con đường native PSI + optional language server.
4. **Nim grammar phân tích được**: Grammar Nim tuy có indentation-sensitive nhưng không phức tạp hơn Python Grammar (đã có native PSI plugin thành công).

### Kế hoạch thực thi

| Phase | Action |
|-------|--------|
| Phase 0 | Skeleton lexer/parser với ~50 token types phổ biến nhất |
| Phase 1 | GrammarKit BNF đầy đủ cho core grammar; stub index declarations |
| Phase 2 | Tích hợp nimsuggest daemon cho semantic completion & type hover |
| Phase 3 | Framework-specific PSI extensions (route annotations, DI tokens) |

---

## Hệ quả

- **Tích cực**: Plugin hoạt động offline, tích hợp sâu với Platform, nền tảng vững cho framework features.
- **Tiêu cực**: Phase 1 tốn 4-6 tuần xây dựng grammar; cần duy trì grammar file khi Nim thay đổi syntax.
- **Nợ kỹ thuật**: Grammar sẽ chưa cover 100% macro/template syntax ở v1; fallback graceful cần thiết.

---

## Tham khảo

- [IntelliJ Platform SDK – Implementing Parser and PSI](https://plugins.jetbrains.com/docs/intellij/implementing-parser-and-psi.html)
- [Grammar-Kit plugin](https://github.com/JetBrains/Grammar-Kit)
- [Nim Language Specification](https://nim-lang.org/docs/manual.html)
- [nimlangserver](https://github.com/nim-lang/langserver)
- [nimsuggest](https://github.com/nim-lang/Nim/tree/devel/nimsuggest)
