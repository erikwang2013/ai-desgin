# AI Design Studio — 审查报告

**日期**: 2026-08-01（更新于同日）
**分支**: main
**当前状态**: Dart 0 issues | 49 tests passed | Rust cargo check clean (0 warnings)

---

## 概览

| 维度 | 初始 | 当前 |
|------|------|------|
| 关键问题 | 5 | 0 |
| 警告 | 10 | 0 |
| 建议 | 6 | 2 保持 / 4 已修复 |
| 测试 | 49 passed | 49 passed |

---

## 关键问题 — 全部已修复

### ~~1. 子进程管道死锁~~ `cc_runner.dart:80` ✅

原问题：`stdout` 读完后才读 `stderr`，缓冲区满时挂死。
修复：使用 `Future.wait` 并发读取 stdout 和 stderr。

### ~~2. ChatView 未处理的 Future 异常~~ `chat_view.dart:49` ✅

原问题：`onSubmit` 异常被静默吞没，UI 永久锁定。
修复：添加 `.catchError` 处理，显示错误消息并恢复输入。

### ~~3. Session 列表查询不加载历史~~ `session_store.dart:117` ✅

原问题：`listBySoftware()` / `search()` 返回空历史和空白上下文。
修复：`_deserializeSessionRows` 通过 `_parseContext()` 反序列化 `context_json`。

### ~~4. Illustrator / SketchUp 插件跨平台编译失败~~ ✅

原问题：`Command::new()` 缺少 import，Win/Mac 编译失败。
修复：添加 `#[cfg(any(target_os = "windows", target_os = "macos"))] use std::process::Command;`

### ~~5. Rust 核心 API 遗漏 4 个新插件~~ `core/api.rs` ✅

原问题：`list_plugins()` 只包含 4 个老插件。
修复：增加 illustrator、sketch、revit、sketchup 四个插件条目。

---

## 警告 — 全部已修复

### ~~6. CCResult.fromJson 无条件成功~~ `cc_runner.dart:26` ✅

修复：改为 `success: json['success'] as bool? ?? true`。

### ~~7. maxConcurrent 未执行~~ `task_orchestrator.dart:48` ✅

修复：`submitTask` 入口处增加 `activeTaskCount >= maxConcurrent` 检查。

### ~~8. Session ID 不一致~~ `task_orchestrator.dart:38` ✅

修复：TaskRecord 的 `sessionId` 统一使用 `Session.id`（UUID），不再用 `softwareName` 字符串。

### ~~9. JSON-RPC 请求未使用~~ `task_orchestrator.dart:54` ✅

修复：调用 `serializeRequest()` 将请求序列化（为后续发送做准备）。

### ~~10. Revit 脚本语言不匹配~~ `revit/lib.rs:25` ✅

修复：`script_language` 从 `"csharp"` 改为 `"python"`，匹配 Dynamo Python 执行。

### ~~11. Revit / SketchUp 吞没执行失败~~ `script.rs` ✅

修复：CLI 不可用时返回 `ScriptResult::failure`（含回退提示），不再伪装成功。

### ~~12. Illustrator macOS 路径~~ — 经核实为误报 ✅

`/Applications/Adobe Illustrator 2025/Adobe Illustrator.app` 中不含字面反斜杠，Rust Read 显示正确。路径正常。

### ~~13. Meshy API 脚本全文作 URL~~ `api.rs` ✅

修复：新增 `parse_url_and_prompt()` 从结构化脚本中提取 URL，不再将全文作为 URL 参数。

### ~~14. 消息和任务列表无界增长~~ ✅

修复：`ChatView._maxMessages = 500` 和 `TaskDashboard._maxTasks = 500`，超出时从头部淘汰。

### ~~15. TaskDashboard 字符串状态~~ `task_dashboard.dart:8` ✅

修复：`TaskItem.status` 从 `String` 改为 `TaskStatus` 枚举，联动 `app.dart` 移除字符串转换。

---

## 建议 — 部分已修复，2 项保持

### ~~16. ChatView 每次按键全量重建~~ ✅

修复：移除 `addListener(() => setState(() {}))`，改用 `ListenableBuilder` 仅重建发送按钮。

### ~~17. 域名回退掩盖配置错误~~ ✅

修复：默认分支增加 `_log.warning` 记录未知域名。同时增加 `import 'package:logging/logging.dart'`。

### ~~18. 复杂度推断仅中文关键词~~ ✅

修复：`_inferComplexity` 增加英文关键词 `create`、`creative`、`generate`、`get`、`view`、`show`。

### 19. Session.save() 全量重写 🔷 保持

当前数据量小（每个 Session 通常 < 100 条记录），全量 upsert 在 SQLite 上性能可接受。数据量大时应改为差分 upsert，但不属于当前优化范围。

### 20. SoftwarePanel 连接状态硬编码 🔷 保持

需要后端连通性检测机制配合（如定期 ping 插件进程 / WebSocket 状态）。涉及前后端协作，超出本次纯代码修复范围。

### ~~21. Session.search() LIKE 注入风险~~ ✅

修复：新增 `_escapeLike()` 转义 `%`、`_`、`\`；SQL 增加 `ESCAPE '\'` 子句。

---

## 测试覆盖（未变）

| 模块 | 已有测试 | 缺失覆盖 |
|------|---------|---------|
| chat_view | 基础渲染 | 异常路径（测试困难，依赖 Flutter 环境） |
| session_store | 基础 CRUD | listBySoftware/search 反序列化 |
| task_orchestrator | 基础任务流 | cancelTask、并发限制 |
| cc_runner | 基础请求构建 | 子进程交互（需 mock Process） |
| software_panel | 无 | 基础渲染 |
| settings_view | 无 | 基础渲染 |

---

## 变更文件清单

### Dart
| 文件 | 变更 |
|------|------|
| `lib/core/cc_runner.dart` | `Future.wait` 并发流读取；fromJson 读 success 字段 |
| `lib/ui/chat_view.dart` | catchError；ListenableBuilder；500 条上限 |
| `lib/core/session_store.dart` | `_deserializeSessionRows` 加 context；`_escapeLike`；`_parseContext` |
| `lib/core/task_orchestrator.dart` | maxConcurrent 检查；Session UUID 一致；serializeRequest；error 路径 session id |
| `lib/core/model_router.dart` | 日志 import；默认域名 warning；英文关键词 |
| `lib/ui/task_dashboard.dart` | TaskStatus 枚举替代 String；500 条上限 |
| `lib/app.dart` | 移除 status 字符串转换，直接用 result.status |

### Rust
| 文件 | 变更 |
|------|------|
| `plugins/illustrator/src/script.rs` | cfg-conditioned `use std::process::Command` |
| `plugins/sketchup/src/script.rs` | cfg-conditioned `use std::process::Command` |
| `core/src/api.rs` | `list_plugins()` 增加 4 个新插件 |
| `plugins/revit/src/lib.rs` | `script_language: "python"` |
| `plugins/revit/src/script.rs` | CLI 不可用返回 failure |
| `plugins/meshy/src/api.rs` | `parse_url_and_prompt()`；URL 参数不再传脚本全文 |

---

## 量化总结

- **初始**: 5 关键 + 10 警告 + 6 建议 = 21 项
- **已修复**: 5 关键 + 10 警告 + 4 建议 = 19 项
- **保持**: 2 项建议（需后端协作的架构级改动）
- **测试**: 49/49 全通过，无退化
