# AI Design Studio — 深度审查报告 v10

**日期**: 2026-07-31
**版本**: 1.1.5
**测试**: 52/52 通过 ✅ | **静态分析**: 无问题 ✅
**代码量**: 2,319 行 Dart 源码 + 671 行测试代码

---

## 一、测试结果总览

| 类别 | 文件 | 测试数 | 结果 |
|------|------|--------|------|
| Core | `cc_process_manager_test.dart` | 5 | ✅ |
| Core | `cc_runner_test.dart` | 3 | ✅ |
| Core | `model_router_test.dart` | 5 | ✅ |
| Core | `plugin_manager_test.dart` | 7 | ✅ |
| Core | `session_store_test.dart` | 5 | ✅ |
| Core | `task_orchestrator_test.dart` | 8 | ✅ |
| Models | `session_test.dart` | ~2 | ✅ |
| Plugin SDK | `design_plugin_test.dart` | ~5 | ✅ |
| UI | `chat_view_test.dart` | 1 | ✅ |
| UI | `plugin_marketplace_test.dart` | ~2 | ✅ |
| UI | `shell_test.dart` | ~4 | ✅ |
| Widget | `widget_test.dart` | 1 | ✅ |

**总计**: 52 tests, all passed. `flutter analyze`: no issues found.

---

## 二、发现的问题

### P1 — 需要修复

#### 1. `cancelTask` 不处理队列中的任务
**文件**: `lib/core/task_orchestrator.dart:143`

`cancelTask()` 只更新了 `_tasks` map 中的状态为 cancelled，但没有从 `_taskQueue` 中移除对应的 `_QueuedTask`。当队列中的任务最终被 `_processQueue()` 出队时，它仍会执行并通过 `submitTask` 创建一个新记录覆盖之前的 cancelled 状态。

**修复**: 在 `cancelTask` 中遍历 `_taskQueue`，找到匹配的 queued task 并移除，同时 complete 其 completer。

#### 2. `CCRunner` 并发场景下进程泄漏
**文件**: `lib/core/cc_runner.dart:54-57`

`_currentProcess` 是单个引用。当 `maxConcurrent > 1` 时，后启动的 `execute()` 会覆盖 `_currentProcess`，导致之前的进程变成孤儿进程（无法被 cancel 杀掉）。

**修复**: 改用 `Map<String, Process>` 按 task/session ID 管理，或使用 `Set<Process>` 追踪所有活跃进程。

---

### P2 — 建议修复

#### 3. `config/model-routing.yaml` 存在但从未被加载
**文件**: `config/model-routing.yaml` vs `lib/app.dart:69-79`

配置文件 `config/model-routing.yaml` 包含完整的路由规则，但 `ModelRouter` 在 `app.dart` 中使用硬编码的 YAML 字符串初始化。该配置文件是死配置。

**修复**: 要么删除 `config/model-routing.yaml`，要么改为从文件加载。

#### 4. `_sessions` Map 无界增长
**文件**: `lib/core/task_orchestrator.dart:32`

`_tasks` map 有 `pruneTasks()` 方法限制增长，但 `_sessions` map 从未清理。每个新软件名创建一个 session 并永久保留，且 session 的 `history` 列表也会无限增长。

**修复**: 添加 session 淘汰机制，为 `Session.addRecord()` 添加条数上限。

#### 5. `_MainShellState` 未释放资源
**文件**: `lib/app.dart:42-57`

`_pluginManager` 创建后从未调用 `disposeAll()`，`_sessionStore` 创建后也未关闭数据库连接。`_MainShellState` 没有 `dispose()` 方法。

**修复**: 添加 `dispose()` 方法清理资源。

#### 6. `_connectionStatus` 始终为 false，永不更新
**文件**: `lib/app.dart:100-102`

```dart
for (final p in _pluginManager.getAll()) {
  _connectionStatus[p.id] = false;  // 全部初始化为 false
}
```

之后没有任何地方更新 `_connectionStatus`。`SoftwarePanel` 中所有插件永远显示「未连接」。实际连接状态检查逻辑（`checkConnection()`）从未被调用。

**修复**: 添加后台连接检测逻辑，或在 UI 中去掉不工作的状态指示器。

#### 7. `PluginManager.initializeAll` 从未被调用
**文件**: `lib/core/plugin_manager.dart:23` vs `lib/app.dart`

`PluginManager` 提供了 `initializeAll()` 方法，但 `_MainShellState` 从未调用它。虽然 BuiltInPlugin 的 `initialize()` 直接返回 true（无副作用），但如果将来有第三方插件需要初始化，它们不会被初始化。

**修复**: 在 `_initOrchestrator` 中注册插件后调用 `initializeAll()`。

#### 8. 竞态条件风险：`_processQueue` 的 await 链
**文件**: `lib/core/task_orchestrator.dart:170-188`

`_processQueue` 调用 `submitTask`，其中包含多个 await 点。在 await 期间，另一个 `submitTask` 调用可能穿插执行，导致队列和 `_activeCount` 状态不一致。虽然 Dart 单线程事件循环减轻了大部分风险，但逻辑上存在隐患。

---

### P3 — 优化建议

#### 9. 缺少 const 构造函数
多处可以使用 `const` 构造函数来提升性能：
- `ChatMessage` (`lib/ui/chat_view.dart:3`)
- `PluginInfo` (`lib/ui/plugin_marketplace.dart:8`)
- `PluginMeta` (`lib/models/plugin.dart:3`)
- `TaskItem` (`lib/ui/task_dashboard.dart:5`)

#### 10. 软件图标/描述分离存储
**文件**: `lib/core/builtin_plugins.dart:62-101`

`softwareIcons` 和 `softwareDescriptions` 是两个独立的 Map，与 `builtInPlugins` 列表分离维护。添加新插件需要在三个地方更新。建议将这些信息作为 `BuiltInPlugin` 的字段。

#### 11. 缺少集成测试
当前所有测试都是单元测试或单个 widget 测试。没有端到端的用户流程测试（例如：选择领域 → 输入任务 → 查看结果 → 检查任务面板）。

#### 12. 缺少全局错误处理
`app.dart:96-98` 中的 `catch (_)` 静默吞掉数据库初始化错误。应用没有全局错误边界或 crash reporter。

#### 13. `CCRunner._buildPrompt` 方法过长
**文件**: `lib/core/cc_runner.dart:180-236`

56 行的 prompt 构建方法包含大量硬编码的软件-语言映射。可考虑将其移到配置文件中。

#### 14. 路由字符串硬编码
**文件**: `lib/app.dart:31`

```dart
routes: {'/settings': (_) => const SettingsView()},
```

路由路径使用字符串字面量，容易拼写错误。建议使用命名常量。

#### 15. 缺失 `cancelTask` 队列场景的单元测试
`test/core/task_orchestrator_test.dart` 中的 `cancelTask` 测试创建了一个直接执行的任务并取消它，但没有测试「任务在队列中等待时被取消」的场景。

---

## 三、架构评分

| 维度 | 评分 | 说明 |
|------|------|------|
| 代码结构 | ⭐⭐⭐⭐ | 清晰的分层：models / core / plugin_sdk / ui |
| 测试覆盖 | ⭐⭐⭐ | Core 模块覆盖好，UI 和集成测试薄弱 |
| 错误处理 | ⭐⭐⭐ | 基本覆盖，但静默吞异常的情况较多 |
| 资源管理 | ⭐⭐ | 缺少 dispose 清理，无界 Map 增长 |
| 可扩展性 | ⭐⭐⭐⭐ | Plugin SDK 设计良好，路由系统灵活 |
| 配置管理 | ⭐⭐ | model-routing.yaml 未加载，硬编码配置 |

**综合评分**: ⭐⭐⭐ (3.0/5)

---

## 四、文件行数统计

| 文件 | 行数 |
|------|------|
| `lib/core/cc_runner.dart` | 237 |
| `lib/core/session_store.dart` | 202 |
| `lib/core/task_orchestrator.dart` | 199 |
| `lib/ui/plugin_marketplace.dart` | 187 |
| `lib/app.dart` | 172 |
| `lib/ui/chat_view.dart` | 162 |
| `lib/ui/task_dashboard.dart` | 158 |
| `lib/ui/shell.dart` | 132 |
| `lib/core/cc_process_manager.dart` | 131 |
| `lib/core/model_router.dart` | 120 |
| `lib/ui/software_panel.dart` | 118 |
| `lib/core/builtin_plugins.dart` | 101 |
| 其他文件 | < 100 行 each |

所有文件均 < 500 行，符合项目规范 ✅。

---

## 五、总结

| 优先级 | 数量 | 要点 |
|--------|------|------|
| **P1** | 2 | cancelTask 不处理队列任务、CCRunner 并发进程泄漏 |
| **P2** | 6 | model-routing.yaml 死配置、session 无界增长、资源未释放、连接状态永为 false、initializeAll 未调用、竞态条件风险 |
| **P3** | 7 | const 优化、图标/描述分离、集成测试、全局错误处理、prompt 过长、路由硬编码、队列取消测试缺失 |

**结论**: 代码库基础扎实，52 个测试全部通过，静态分析零警告。主要风险集中在 P1 的两个并发/队列 bug 和 P2 的资源管理问题。建议优先修复 P1 和 P2 中的资源释放问题。
