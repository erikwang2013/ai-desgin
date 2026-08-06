# 审查报告 — 2026-08-06 (v17) — 第二轮深度审查修复

## 执行摘要

针对「生态是否完整、功能扩展空间、剩余问题」的第二轮深度审查，发现 10 个问题（1 个 P1 结构性、5 个 P2 功能缺口、4 个 P3 健康问题），全部修复。70/70 测试通过，`dart analyze` 零问题，`cargo check` / `cargo clippy` 零警告。版本统一为 1.4.0。

## 测试结果

```
flutter test            → 70 passed, 0 failed
dart analyze lib test   → No issues found
cargo check --workspace → Finished (0 warnings)
cargo clippy --workspace → Finished (0 warnings)
```

## 已修复问题（10 个）

| # | 级别 | 问题 | 修复 |
|---|------|------|------|
| 1 | P1 | Rust workspace 与 Flutter 完全脱节（flutter_rust_bridge 从未 codegen，Rust 代码不可达） | 诚实分层：不伪造集成，README 明确标注 Rust crates 为脚本生成模块，UI 以 Auto/Manual 徽标如实展示执行能力 |
| 2 | P2 | API key/endpoint 设置是死设置（存了 prefs 但从不使用） | `CCRunner.apiBaseUrl/apiAuthToken` 静态字段，启动与保存时注入子进程环境变量 `ANTHROPIC_BASE_URL` / `ANTHROPIC_AUTH_TOKEN` |
| 3 | P2 | 语言指令未传播到 Claude prompt | `CCRunner.responseLanguage`：启动时从 LocaleProvider 注入，切换语言即时生效 |
| 4 | P2 | CCRunner 进程无并发控制，maxConcurrent=3 失效 | `Map<String, Process>` 按任务 key 跟踪，`cancel(key:)` 按任务取消，超时/完成即移除 |
| 5 | P2 | 启动探测串行 62 次 | 并行探测：`Future.wait` 聚合，`Map.fromIterables` 写入连接状态 |
| 6 | P2 | 切片器伪执行（CLI 只接受模型文件，不接受生成脚本） | 从 CLI 执行映射移除 6 个切片器，文档与界面如实标注「脚本手动执行」，真实 CLI 仅剩 Blender/FreeCAD/OpenSCAD |
| 7 | P3 | `pruneTasks` 存在但从未调用，任务列表无上限 | `submitTask` 完成后调用 `pruneTasks(keep: 200)`，只修剪终态任务 |
| 8 | P3 | 任务历史恢复后乱序 | restore 后按 `createdAt` 降序排序 |
| 9 | P3 | 软件面板无搜索/分组/执行状态，任务详情不可复制 | 面板重写：搜索框 + 6 领域分组计数 + Auto/Manual 徽标 + 连接状态指示器；任务卡片可打开详情对话框（脚本全文、复制按钮） |
| 10 | P3 | 明文 API key 存储、版本/文档漂移 | 设置页注明「明文存储于本地 prefs，仅用于注入 CLI 进程」；版本统一 1.4.0（pubspec / version.dart / Cargo.toml 三处一致），README 中英双语同步执行层说明 |

## 执行层（修复 #6 深化）

- **Auto（3 个）**：blender / freecad / openscad — `LocalScriptExecutor` 真实执行（`--version` 探测 + 60s 缓存 + `runInShell`），面板显示 Auto 徽标与实时连接状态。
- **Manual（59 个）**：Figma、Photoshop、切片器、Adobe 全家等 — 诚实回退：生成脚本 + 手动执行提示，面板显示 Manual 徽标。
- **切片器说明**：Cura/PrusaSlicer/OrcaSlicer 等 CLI 只接受模型文件或 key=value 设置，无法执行生成脚本，故不列入自动执行。

## 新增能力

- 任务详情对话框：点击历史任务卡片查看生成脚本全文，一键复制到剪贴板。
- 软件面板：搜索过滤、领域分组（工业设计/三维/平面/Web/室内/建筑）、Auto/Manual 执行徽标。
- API 兼容层：自定义 endpoint + key 真实注入 Claude CLI 子进程。
- 语言穿透：所有 Claude 调用携带当前 UI 语言指令（中文回复等）。

## 新增/更新测试（65 → 70）

| 测试 | 覆盖 |
|------|------|
| `test/ui/software_panel_test.dart`（新增 ×3） | Auto/Manual 徽标、领域分组、搜索过滤 |
| `test/core/cc_runner_test.dart`（新增 ×2） | 语言指令注入 prompt、未设置时省略 |
| `test/core/local_script_executor_test.dart`（更新） | hasCommand 诚实化：仅 blender/freecad/openscad true，切片器 false |
| `test/core/task_orchestrator_test.dart`（更新） | FakeCCRunner 适配新 `key` 参数签名 |

## 版本与一致性

- `pubspec.yaml` / `lib/core/version.dart` / `rust/Cargo.toml`（workspace.package，crates 通过 `version.workspace = true` 继承）均统一为 **1.4.0**。
- pubspec description 同步为「62+ design software」。
- README / README_EN：执行层架构图、切片器注释、测试数量（70）、审查报告链接全部同步。
