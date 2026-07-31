# AI Design Studio — 深度审查报告 v7

**日期**: 2026-07-31
**版本**: 1.1.2
**审查范围**: 全部源代码 (21 个 Dart 文件, 2209 行), 12 个测试文件
**测试结果**: 49/49 通过
**静态分析**: 0 issues

---

## 总览

| 维度 | 评分 | 说明 |
|------|------|------|
| 测试覆盖 | A | 49 个测试全部通过，覆盖核心模块和 UI |
| 静态分析 | A | `flutter analyze` + `dart analyze` 零问题 |
| 代码健康度 | A- | 所有文件 < 220 行，职责分明 |
| 架构设计 | B+ | 分层清晰，少数边界不一致 |
| 健壮性 | B | 存在几处 bug 和边界条件缺陷 |
| 安全性 | A | 无 XSS/SQL 注入/密钥泄露风险 |

---

## 发现汇总

### P1 — Bug (3 项)

#### 1. `CCResult.fromJson` 未解析 `error` 字段

- **文件**: `lib/core/cc_runner.dart:26-34`
- **问题**: `fromJson` 工厂构造函数未从 JSON 中读取 `error` 字段，导致来自 JSON 响应的错误信息被静默丢弃。
- **影响**: 如果 Claude Code 返回包含 error 字段的 JSON，调用方看到的会是 `success=true` 的正常结果，而非错误。

```dart
// 当前代码
factory CCResult.fromJson(Map<String, dynamic> json) {
  return CCResult(
    script: json['script'] as String?,
    scriptLanguage: json['scriptLanguage'] as String?,
    explanation: json['explanation'] as String?,
    modelUsed: json['modelUsed'] as String?,
    success: json['success'] as bool? ?? true,
    // 缺少: error: json['error'] as String?,
  );
}
```

#### 2. stdout JSON 解析对多行响应脆弱

- **文件**: `lib/core/cc_runner.dart:114-125`
- **问题**: 逐行解析 stdout，每行尝试 `jsonDecode`。如果 Claude Code 输出多行 JSON 或 JSON 值中包含换行符，解析将失败。
- **影响**: 复杂脚本（如多行 Python/JS 代码嵌入 JSON 的 `script` 字段中）无法被正确解析。
- **建议**: 先收集完整输出，再整体解析；或使用 JSON 流式解析器处理 NDJSON 格式。

#### 3. `_toggleInstall` 无法恢复非内置插件

- **文件**: `lib/ui/plugin_marketplace.dart:75-78`
- **问题**: 卸载插件后，重新安装时只在 `builtInPlugins` 列表中搜索。外部/动态加载的插件卸载后将永久丢失。
- **影响**: 如果未来支持第三方插件安装，卸载后无法恢复。
- **当前缓解**: 目前所有插件均为内置，暂无实际影响。

### P2 — 边界条件 / 代码质量 (5 项)

#### 4. Settings 入口的 PluginMarketplace 使用独立 PluginManager 实例

- **文件**: `lib/ui/settings_view.dart:24` → `lib/ui/plugin_marketplace.dart:28,39-40`
- **问题**: Settings 页面导航到 `PluginMarketplace()` 时不传 PluginManager，导致使用 `_createDefaultPluginManager()` 创建新实例。从 Settings 卸载的插件不会同步到主界面 `_MainShellState._pluginManager`。
- **影响**: 两个入口的插件状态不一致。用户从 Settings → 插件市场卸载插件后，回到主界面插件面板仍显示为已安装。
- **建议**: Settings 页面需要访问共享的 PluginManager 实例。

#### 5. `_inferComplexity` 英文关键词大小写敏感

- **文件**: `lib/core/model_router.dart:94-118`
- **问题**: 关键词列表全为小写（如 `rename`、`export`），但 `String.contains()` 大小写敏感。用户输入 `"Rename layer"` 不会被匹配为 simple。
- **建议**: 对 task 做 `toLowerCase()` 后再匹配。

#### 6. `_ccRunner.isAvailable()` 每次调用都启动进程

- **文件**: `lib/core/cc_runner.dart:55-69`
- **问题**: `isAvailable()` 每次调用都执行 `Process.run('claude', ['--version'])`。在 `TaskOrchestrator.submitTask` (line 60) 中每次提交任务都调用一次。
- **影响**: 在高频使用场景下造成不必要的进程开销和 10s 超时等待。
- **建议**: 缓存检查结果，设置 TTL（如 60s）。

#### 7. `_activeCount` 在异常路径可能不会递减

- **文件**: `lib/core/task_orchestrator.dart:48,96,99`
- **问题**: `_activeCount++` 后，递减在 try 块末尾 (line 96) 和 catch 块 (line 99)。但如果 `_ccManager.executeWithClaude` 正常返回但 `plugin.execute()` 抛出未经捕获的错误（在 line 71 前），则 `_activeCount` 永远不会递减。
- **建议**: 使用 try/finally 确保递减。

```dart
// 当前: 两个递减点分散在 try 和 catch 中
// 建议: 统一使用 finally
try {
  // ... work
  return updated;
} catch (e) {
  // ... error handling
  return failed;
} finally {
  _activeCount--;  // 总是执行
}
```

#### 8. `cc_process_manager.dart` — `reduce` 在空集合上会抛出

- **文件**: `lib/core/cc_process_manager.dart:42-43`
- **问题**: `_sessions.entries.reduce()` 在空集合上会抛出 `StateError`。虽然后面有条件保护（line 41 `_sessions.length >= maxProcesses`），但如果 `maxProcesses` 被设为 0 且 `_evictIdleSessions` 清空了所有 session，`length(0) >= 0` 为 true，会进入 reduce 抛异常。
- **当前缓解**: `maxProcesses` 默认 3，不太可能被设为 0。
- **建议**: 加防御性检查 `if (_sessions.isEmpty) return;`

### P3 — 优化建议 (4 项)

#### 9. `PluginManager.initializeAll` 可并行化

- **文件**: `lib/core/plugin_manager.dart:23-27`
- **问题**: 逐个 `await plugin.initialize(ctx)`，N 个插件串行初始化。
- **建议**: 使用 `Future.wait` 并行初始化。

#### 10. Prompt 模板硬编码

- **文件**: `lib/core/cc_runner.dart:160-216`
- **问题**: `_buildPrompt` 方法包含一个 70+ 行的硬编码字符串模板。修改 prompt 需要重新编译。
- **建议**: 考虑将 prompt 模板外部化到配置文件（如 `config/prompt_template.yaml`）。

#### 11. `pubspec.yaml` — 存在未使用的依赖

- **问题**: `flutter_rust_bridge: ^2.0.0` 和 `ffi: ^2.1.0` 被声明为依赖，但代码中未发现对这两个包的实际引用。`mockito` 和 `build_runner` 声明为 dev_dependency，但测试文件中未发现 mockito 的使用。
- **建议**: 清理未使用的依赖以减少包体积。

#### 12. Session Store 的 `_loadSessionRowsWithHistory` 存在 N+1 查询

- **文件**: `lib/core/session_store.dart:133-152`
- **问题**: 对每个 session 行执行一次单独的 `task_records` 查询。加载 100 个 session 会产生 101 次数据库查询。
- **建议**: 使用 JOIN 或 IN 查询一次性加载所有关联的 task_records。

---

## 已有优点（上次修复已验证）

以下问题在 v3-v6 中已修复，本次验证确认正确：

1. ✅ 空 session 处理（使用 `if (row == null) return` 替代 try/catch）
2. ✅ `createSession` maxProcesses 检查（先驱逐空闲再检查容量）
3. ✅ 测试 `initialTasks` 边界情况
4. ✅ `SessionContext` 不可变默认值（使用 `const {}` / `const []`）
5. ✅ SQL LIKE 查询转义（`_escapeLike` 方法）

---

## 测试覆盖率分析

| 模块 | 测试数 | 覆盖情况 |
|------|--------|----------|
| `cc_runner` | 3 | 构造函数、fromJson、failure |
| `cc_process_manager` | 5 | CRUD、buildRequest、maxProcesses |
| `task_orchestrator` | 5 | submitTask(成功/失败)、cancel、session |
| `model_router` | 5 | 路由规则、回退、override |
| `session_store` | 5 | CRUD、listBySoftware、search |
| `plugin_manager` | 3 | 注册、查询、分类 |
| `shell` | 9 | 渲染、domain切换、tab切换 |
| `chat_view` | 1 | 输入框和发送按钮 |
| `plugin_marketplace` | 3 | 已安装列表、安装/卸载 |
| `widget` | 10 | App 默认渲染 |
| **总计** | **49** | |

### 缺失的测试覆盖

1. `ChatView` 无消息发送流程测试（只有渲染测试）
2. `TaskDashboard` 无独立 widget 测试
3. `CCRunner.execute` 方法无集成/单元测试
4. `SessionStore.search` 无 LIKE 转义安全测试

---

## 建议优先级

| 优先级 | 数量 | 行动 |
|--------|------|------|
| 🔴 P1 — 立即修复 | 3 | CCResult.fromJson 补 error 字段、stdout 解析改进、toggleInstall 边界 |
| 🟡 P2 — 本迭代修复 | 5 | PluginManager 实例共享、大小写匹配、缓存 isAvailable、finally 保护 _activeCount、reduce 防御 |
| 🟢 P3 — 后续优化 | 4 | 并行初始化、prompt 外置、依赖清理、N+1 查询优化 |

---

## 结论

代码库整体质量良好。静态分析零问题，49 个测试全部通过，文件长度均在健康范围内。本次发现 3 个 P1 bug 和 5 个 P2 问题，主要是边界条件处理和健壮性方面的改进空间。无安全漏洞，无严重架构缺陷。
