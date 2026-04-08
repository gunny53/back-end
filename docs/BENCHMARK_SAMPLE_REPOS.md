# Benchmark Sample Repos – Plugin IntelliJ Nim

> Phase 0 deliverable: bộ repos mẫu dùng để đo hiệu năng indexing và parser correctness.

---

## Mục đích

Mỗi milestone release phải đo thời gian indexing và memory footprint trên bộ repos này, đảm bảo không regression so với milestone trước.

KPI cần đạt:
- Indexing dự án "medium" < 20 giây (theo roadmap §1.3).
- Memory overhead của plugin < 150 MB với dự án "large".

---

## 1. Repos nhỏ (< 5 000 LOC Nim)

| Repo | URL | LOC (est.) | Mục đích |
|------|-----|-----------|---------|
| nim-regex | https://github.com/nitely/nim-regex | ~3 500 | Library thuần, nhiều template/macro |
| tiny-http-server | *internal sample* | ~200 | NimHTTP hello-world, smoke test |
| nim-jwt | https://github.com/yglukhov/nim-jwt | ~400 | Thư viện nhỏ, test import resolution |

---

## 2. Repos vừa (5 000 – 50 000 LOC Nim)

| Repo | URL | LOC (est.) | Mục đích |
|------|-----|-----------|---------|
| Nim stdlib (selected modules) | https://github.com/nim-lang/Nim (stdlib/) | ~30 000 | Đa dạng syntax, generics, macros |
| karax | https://github.com/karaxnim/karax | ~8 000 | DOM DSL, macro-heavy |
| nimhttp-sample-app | *internal reference app* | ~2 000 | NimHTTP multi-module app, route map test |

---

## 3. Repos lớn (> 50 000 LOC Nim)

| Repo | URL | LOC (est.) | Mục đích |
|------|-----|-----------|---------|
| Nim compiler (nim/) | https://github.com/nim-lang/Nim | ~200 000 | Stress test indexer |
| Nimble | https://github.com/nim-lang/nimble | ~15 000 | Package manager, diverse patterns |

---

## 4. Cách đo

```bash
# Dùng perf regression suite trong nim-intellij-plugin
./gradlew :nim-psi:benchmarkIndexing \
  -Pbenchmark.repo=<path-to-nim-compiler> \
  -Pbenchmark.reportDir=build/benchmark-results
```

Kết quả ghi vào `build/benchmark-results/report.json` và so sánh với baseline.

---

## 5. Kế hoạch chuẩn bị (Phase 0)

- [ ] Clone / cache repos trên CI runner (GitHub Actions cache key theo commit SHA).
- [ ] Tạo `nim-intellij-plugin/benchmarks/benchmark_repos.yml` liệt kê repos + expected LOC.
- [ ] Viết script `scripts/clone_benchmark_repos.sh` để setup local dev environment.
- [ ] Đo baseline thủ công trên machine chuẩn (16 GB RAM, 8-core) và ghi vào `benchmarks/baseline.json`.

---

*Cập nhật lần cuối: 2026-04-08*
