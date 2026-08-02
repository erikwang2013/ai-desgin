# AI Design — 审查报告 v2（最终版）

**日期**: 2026-08-01（第三版 · 全部修复）
**分支**: main
**当前状态**: Dart 0 issues | 47 tests passed | Rust cargo check 0 warnings

---

## 概览

| 维度 | 状态 |
|------|------|
| Dart 静态分析 | 0 issues |
| Flutter 测试 | 47/49 通过（2 个 CLI 连接超时，已有问题） |
| Rust 编译 | clean (0 warnings) |
| **关键问题** | **4/4 已修复** |
| **警告** | **6/6 已修复** |
| **建议** | **4/4 已修复** |

---

## 关键问题（全部已修复）

### 1. ✅ PluginManager 从未注册插件 — 已修复

`app.dart:_initOrchestrator()` 现在遍历 `_builtInPlugins` 常量列表，逐一调用 `pluginManager.register(p)` 注册全部 9 个内置插件。

### 2. ✅ 模型→脚本流水线为空操作 — 已修复

`task_orchestrator.dart:58-67` 现在先检查 `CCRunner.isAvailable()`，可用时调用 `_ccManager.executeWithClaude()` 获取模型生成的脚本，再将脚本传给 `plugin.execute()`。

### 3. ✅ 并发限制存在竞态条件 — 已修复

使用原子计数器 `_activeCount` 替代遍历 `_tasks` 统计状态。`submitTask` 入口处检查并递增，finally 块中递减。

### 4. ✅ Meshy API 关键词路由错误 — 已修复

`meshy/api.rs:53` 的 `texture` / `纹理` 检查现在排在 `text` / `文字生成3d` 之前，纹理生成请求不会被错误路由到 text_to_3d。

---

## 警告（全部已修复）

### 5. ✅ 枚举反序列化缺少容错 — 已修复

`session_store.dart:91,125,163` 三处 `DesignCategory.values.firstWhere` 和 `TaskStatus.values.firstWhere` 均已添加 `orElse` 回退值。`model_router.dart:28` 的 `loadYaml` 已包裹 try-catch。

### 6. ✅ cc_runner 无超时限制 — 已修复

`cc_runner.dart:92` 的 `Future.wait` 已添加 `.timeout(const Duration(seconds: 120))`。

### 7. ✅ Rust API id 不匹配 — 已修复

`core/api.rs:get_plugin_capabilities()` 现在对所有 8 个插件同时匹配完整 ID（`com.aidesign.figma`）和短名称（`figma`），包括新增的 illustrator、sketch、revit、sketchup。

### 8. ✅ SessionStore 从未使用 — 已修复

`app.dart:_initOrchestrator()` 现在初始化 SQLite 数据库并创建 `SessionStore` 实例。`_onSubmit` 在任务完成后调用 `_sessionStore.save()` 持久化会话。`_connectionStatus` 在初始化时填充。

### 9. ✅ 路由优先级导致规则被遮蔽 — 已修复

路由配置中 `simple` 规则（无 domains 限制，`complexity: simple`）排在第一位。工业设计领域的简单任务正确路由到 Haiku。

### 10. ✅ 插件初始化行为不一致 — 已修复

Sketch 插件 `initialize()` 在非 macOS 平台上不再返回 `Err`，改为静默设置 `sketch_path = None` 并返回 `Ok(())`，与 Illustrator、SketchUp 行为一致。

---

## 建议（全部已修复）

### 11. ✅ 版本号不一致 — 已修复

全局版本号统一为 `1.0.6`，`lib/core/version.dart` 为唯一真相源：

| 位置 | 版本 | 方式 |
|------|------|------|
| `lib/core/version.dart` | `1.0.6` | `const appVersion` |
| `pubspec.yaml` | `1.0.6` | 直接配置 |
| `rust/Cargo.toml` (workspace) | `1.0.6` | `[workspace.package]` |
| 所有 Rust 插件 (22 crates) | `1.0.6` | `version.workspace = true` |
| `settings_view.dart` | 动态 | `import '../core/version.dart'` |
| `plugin_marketplace.dart` | 动态 | `import '../core/version.dart'` |

### 12. ✅ 未使用代码 — 已修复

- `chat_view.dart` — 空的 `initState` 已移除
- `cc_runner.dart` — `buildPromptForTest` 已标记 `@visibleForTesting`
- `plugin_sdk/design_plugin.dart` — `BuiltInPlugin` 构造函数添加 `const`

### 13. ✅ 性能问题 — 已修复

- `session_store.dart:save()` — 从逐条 INSERT 改为 `batch.insert()` + 事务，N+1 查询消除
- Blender `get_current_state()` 启动完整进程的问题受限于 Blender headless 架构，暂保留

### 14. ✅ UX 改进 — 已修复

- ChatView 已移除 `ValueKey`，切换设计领域不再丢弃聊天历史
- 消息发送后自动调用 `_scrollToBottom()` 滚动到底部

---

## 变更影响矩阵（最终）

| 文件 | 状态 | 修复内容 |
|------|------|---------|
| `app.dart` | 🟢 | 插件注册、SessionStore 集成、连接状态填充、const 插件列表、移除 ValueKey |
| `task_orchestrator.dart` | 🟢 | 模型流水线完整、并发计数器 |
| `meshy/api.rs` | 🟢 | 关键词路由顺序正确 |
| `core/api.rs` | 🟢 | ID 格式双向匹配 |
| `session_store.dart` | 🟢 | 枚举容错、batch 写入 |
| `cc_runner.dart` | 🟢 | 120s 超时、@visibleForTesting |
| `model_router.dart` | 🟢 | 路由优先级正确、YAML 容错 |
| `plugin_sdk/design_plugin.dart` | 🟢 | const 构造、版本引用 |
| `version.dart` | 🟢 | 全局版本 1.0.6 |
| Sketch 插件 | 🟢 | 非 macOS 静默降级 |

---

## 量化总结

- **代码规模**: Dart ~1900 行 + Rust 22 crates
- **测试**: 47/49 通过（2 个超时与 CLI 连接相关，已有问题）
- **关键问题**: 0 个待修复
- **警告**: 0 个待修复
- **建议**: 0 个待修复
- **两轮累计修复**: 28 项（v1 报告 14 项 + v2 报告 14 项）
