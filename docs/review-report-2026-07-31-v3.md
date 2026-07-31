# AI Design Studio — 代码审查报告 v3

**日期**: 2026-07-31  
**范围**: 全项目审查  
**版本**: 1.0.9

---

## 测试结果总览

| 项目 | 结果 |
|------|------|
| `flutter analyze` | 通过，无问题 |
| 测试总数 | 49 |
| 通过 | 46 |
| 失败 | 3（均为超时） |

### 失败测试详情

| 测试 | 失败原因 |
|------|----------|
| `submitTask completes with success for known software` | 偶发超时（`Process.run` 阻塞） |
| `session is created per software and records history` | 超时 30s + 断言失败 `Expected: <1>, Actual: <0>` |
| `cancelTask cancels a pending task` | 超时 30s |

**根因**: `TaskOrchestrator.submitTask()` 内部直接 `new CCRunner()` 并调用 `isAvailable()` 和 `execute()`，这两个方法分别通过 `Process.run` / `Process.start` 启动 `claude` CLI 进程。测试环境中 `claude --print` 进程可能挂起等待 API 响应，导致测试超时。`CCRunner` 不可注入是根本问题。

---

## 问题分类

### 严重 — 1 项

**1. `CCRunner` 不可注入导致测试不可靠**  
`task_orchestrator.dart:57-58`: `CCRunner()` 在方法内部直接实例化，测试无法 mock。  
**修复**: 将 `CCRunner` 作为构造函数参数注入，测试中传入 mock/fake。

### 中等 — 5 项

**2. 软件列表三次硬编码，存在不同步风险**  
以下三处各自维护一份完全相同的 27 个插件列表：
- `app.dart:104-159` — `_builtInPlugins`（数据源）
- `software_panel.dart:29-57` — `_defaultSoftware`（UI 展示）
- `plugin_marketplace.dart:33-59` — `_plugins`（插件市场）

当前三处 ID 一致，但任何新增插件需同步修改三个文件，极易遗漏。

**建议**: `SoftwarePanel` 和 `PluginMarketplace` 应从 `PluginManager` 读取列表，只维护一份数据源。

**3. `Process.run` 无超时设置**  
`cc_runner.dart:51`: `Process.run(_cliPath, ['--version'])` 无 timeout 参数。如果 CLI 进程挂起，调用方将无限期阻塞。  
**修复**: 使用 `Process.run` 的 `timeout` 参数，或改用 `Process.start` + `Future.timeout`。

**4. `task_orchestrator.dart` 中任务执行缺少 process kill 机制**  
`cancelTask()` 仅将内存中的 `TaskRecord` 标记为 `cancelled`，但不终止正在运行的 `CCRunner` 进程。  
**影响**: 用户取消任务后，后台 `claude` 进程仍继续运行消耗资源。

**5. `SessionStore.listBySoftware()` 和 `search()` 返回无历史记录的 Session**  
`session_store.dart:133-141`: `_deserializeSessionRows` 创建的 Session 没有加载 `history`（与 `load()` 不一致）。  
**影响**: 调用方获取的 Session 列表无法展示任务历史。

**6. `ModelRoute` 缺少校验**  
`model_router.dart:16-20`: 如果 `domains` 和 `complexity` 均为 null，路由会匹配所有任务，这可能不是预期行为。缺少编译时或运行时校验。

### 轻微 / 优化建议 — 6 项

**7. 缺少 `SessionStore` 和 `CCRunner` 的单元测试**  
`SessionStore` 负责持久化，`CCRunner` 负责与 CLI 交互，两者均无测试覆盖。

**8. 魔法数字散落各处**  
- `chat_view.dart:26`: `_maxMessages = 500`
- `task_dashboard.dart:43`: `_maxTasks = 500`
- `cc_process_manager.dart:32`: `maxProcesses = 3`, `idleTimeoutSeconds = 300`
- `cc_runner.dart:92`: `Duration(seconds: 120)`

建议集中到配置常量文件。

**9. `_builtInPlugins` 列表过长**  
`app.dart:104-159`: 27 个插件的列表占 56 行，建议提取到独立文件（如 `core/builtin_plugins.dart`）。

**10. `process.stdin.write(prompt)` 无错误处理**  
`cc_runner.dart:86-87`: 如果进程提前退出，写入 stdin 会静默失败，之后 `stdout.join()` 会等待已关闭的流。

**11. `SoftwarePanel` 中使用 emoji 作为图标**  
`software_panel.dart:29-57`: 使用 emoji 字符作为软件图标，在不同平台上渲染效果不一致。建议使用 Material Icons 或自定义图标资源。

**12. `pubspec.yaml` description 仍为占位文本**  
`pubspec.yaml:2`: `"A new Flutter project."` — 应更新为有意义的应用描述。

---

## 架构评估

### 优点
- **清晰的分层架构**: `core/` (业务逻辑) / `models/` (数据模型) / `ui/` (界面) / `plugin_sdk/` (插件接口) — 职责分明
- **插件系统设计合理**: `DesignPlugin` 抽象接口 + `BuiltInPlugin` 默认实现，支持扩展
- **模型路由有实际价值**: 根据任务复杂度+领域智能选择模型，减少 token 浪费
- **会话持久化**: `SessionStore` 支持 SQLite 存储，含搜索和按软件筛选
- **Material 3 设计**: 全项目使用 M3，UI 一致性良好

### 改进方向
- 考虑引入依赖注入（如 `provider` 或 `riverpod`）替代当前的手动构造函数传递
- `CCRunner` / `TaskOrchestrator` 关系可引入策略模式，便于测试和扩展
- 配置应从 YAML/JSON 文件加载而非硬编码

---

## 安全检查

| 检查项 | 状态 |
|--------|------|
| SQL 注入 | 安全 — 使用参数化查询 (`whereArgs`) |
| LIKE 注入 | 安全 — `_escapeLike()` 转义 `%` `_` `\` |
| 进程注入 | 低风险 — CLI 路径可配置但参数固定 |
| 密钥泄露 | 无明显风险 — 无硬编码密钥 |
| JSON 解析异常 | 已处理 — 所有 `jsonDecode` 外有 try/catch |

---

## 总结

| 维度 | 评分 | 说明 |
|------|------|------|
| 代码质量 | B+ | 结构清晰，命名规范，少量重复代码 |
| 测试覆盖 | C+ | 核心 UI 和部分 core 有覆盖，但 `CCRunner`/`SessionStore` 缺少测试 |
| 可维护性 | B | 三次硬编码列表是主要痛点 |
| 安全性 | A- | 参数化查询 + LIKE 转义，无明显漏洞 |
| 可扩展性 | B+ | 插件 SDK 设计良好，但缺少依赖注入 |

**优先处理**: 修复 3 个失败测试（注入 `CCRunner`），消除三处重复的软件列表。
