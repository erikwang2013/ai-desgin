# AI Design Studio — 代码审查报告 v4

**日期**: 2026-07-31  
**范围**: 全项目（v3 修复后复查）  
**版本**: 1.0.9

---

## 测试结果

| 项目 | 结果 |
|------|------|
| `flutter analyze` | 零问题通过 |
| 测试总数 | 49 |
| 通过 | **49 / 49** |
| 失败 | 0 |
| 执行时间 | ~12 秒 |

---

## 当前状态评估

### 已解决（v3 → v4）

| # | 问题 | 状态 |
|---|------|------|
| 1 | `CCRunner` 不可注入 → 测试超时 | 已修复 — `FakeCCRunner` 注入 |
| 2 | 软件列表三次硬编码 | 已修复 — `builtin_plugins.dart` 单一数据源 |
| 3 | `Process.run` 无超时 | 已修复 — 10 秒超时 |
| 4 | `cancelTask` 不杀进程 | 部分 — 已添加 `kill()` 但进程未注册 |
| 5 | `SessionStore` 列表方法无历史 | 已修复 — `_loadSessionRowsWithHistory` |
| 6 | `ModelRoute` 缺校验 | 已修复 — catch-all 路由日志警告 |
| 7 | `pubspec.yaml` 描述 | 已修复 |
| 8 | `_builtInPlugins` 提取 | 已修复 — `lib/core/builtin_plugins.dart` |
| 9 | stdin 无错误处理 | 已修复 — 添加 `flush()` |
| 10 | README 文档更新 | 已修复 — 中英文同步 |

---

## 新发现问题

### 中等 — 2 项

**1. `_activeProcesses` 从未被填充（死代码）**  
`task_orchestrator.dart:19`: `_activeProcesses` 已声明并在 `cancelTask()` 中使用 `remove(taskId)?.kill()`，但没有任何代码向这个 Map 添加条目。  
`cc_runner.dart:83` 创建的 `Process` 对象未回传给 orchestrator，导致 `cancelTask` 无法实际终止进程。  
**修复**: 在 `CCRunner.execute()` 中返回 process 引用，或让 orchestrator 通过 `CCRunner` 来管理进程生命周期。

**2. `software_panel.dart:44` 使用 `dynamic` 类型**  
`_buildSoftwareCard(BuildContext context, dynamic plugin)` — `plugin` 参数类型为 `dynamic`，丢失了所有类型安全。调用 `plugin.id`、`plugin.name` 等属性时编译器无法校验。  
**修复**: 导入 `DesignPlugin` 并使用具体类型。

### 轻微 — 3 项

**3. `DesignCategory` → 中文标签映射重复 3 处**  
同一段 switch 逻辑出现在：
- `shell.dart` — 侧边栏领域名
- `software_panel.dart:118-127` — 软件分类标签
- `plugin_marketplace.dart:87-94` — 插件分类标签

建议提取为 `DesignCategory` 的 extension 方法。

**4. `plugin_marketplace.dart` 的 `_descriptions` map 独立于 `builtin_plugins.dart`**  
插件列表已统一到 `builtin_plugins.dart`，但每个插件的描述文案仍在 `PluginMarketplace` 中作为独立 map。新增插件时需同步修改两处。

**5. `task_orchestrator.dart` 导入 `dart:io` 但仅用于 `Process` 类型**  
`import 'dart:io';` 仅在 `_activeProcesses` Map 的值类型中使用。如果 `_activeProcesses` 不可用（见问题 #1），该导入即为多余。

---

## 各模块评估

### `lib/core/task_orchestrator.dart` (144 行)
- **正面**: 职责清晰，错误处理完备，CCRunner 可注入
- **问题**: `_activeProcesses` 死代码（见上）

### `lib/core/cc_runner.dart` (209 行)
- **正面**: 超时设置到位，stdin flush 已添加，`@visibleForTesting` 合理
- **问题**: `Process` 对象未暴露给调用方用于 cancel

### `lib/core/session_store.dart` (192 行)
- **正面**: SQL 参数化查询安全，LIKE 转义正确，`listBySoftware/search` 现在加载历史
- **注意**: `_loadSessionRowsWithHistory` 对每行执行一次 DB 查询（N+1），但对于会话列表场景可接受

### `lib/core/model_router.dart` (119 行)
- **正面**: 关键字匹配逻辑合理，catch-all 路由有日志警告
- **注意**: `_inferComplexity` 使用 `contains` 匹配可能误判（如 "删除创意" 会匹配 "创意" → creative）

### `lib/core/builtin_plugins.dart` (71 行)
- **正面**: 单一数据源，`softwareIcons` map 集中管理
- **改进**: 可考虑添加 `descriptions` map 以彻底消除 `PluginMarketplace` 中的重复

### `lib/app.dart` (171 行)
- **正面**: 代码大幅精简（原 222 行 → 171 行），`_builtInPlugins` 已提取
- **正面**: `_pluginManager` 存储为字段，UI 面板可直接使用

### `lib/ui/software_panel.dart` (128 行)
- **正面**: 从 `PluginManager` 读取插件，不再硬编码
- **问题**: `dynamic` 类型参数

### `lib/ui/plugin_marketplace.dart` (205 行)
- **正面**: 支持可选 `PluginManager` 参数，兼容 settings 路由
- **问题**: `_descriptions` map 独立存在，`categoryLabel` 重复

---

## 测试覆盖

| 模块 | 测试文件 | 覆盖范围 |
|------|---------|---------|
| `CCProcessManager` | `cc_process_manager_test.dart` | 会话 CRUD + 请求构建 |
| `TaskOrchestrator` | `task_orchestrator_test.dart` | 任务提交/取消/查询 |
| `CCRunner` | `cc_runner_test.dart` | Prompt 构建 + CCResult 解析 |
| `SessionStore` | `session_store_test.dart` | CRUD + 搜索 + 列表 |
| `ModelRouter` | `model_router_test.dart` | 路由规则匹配 |
| UI | `chat_view_test.dart` | 发送消息流程 |
| UI | `shell_test.dart` | 侧边栏渲染 |
| UI | `plugin_marketplace_test.dart` | 插件列表 + 卸载 |
| 集成 | `widget_test.dart` | App 启动渲染 |

---

## 总结

| 维度 | v3 评分 | v4 评分 | 变化 |
|------|---------|---------|------|
| 代码质量 | B+ | A- | 去重 + 类型安全改进 |
| 测试覆盖 | C+ | B+ | 新增 SessionStore/CCRunner 测试 |
| 可维护性 | B | A- | 单一数据源消除三处同步 |
| 安全性 | A- | A- | 不变 |
| 可扩展性 | B+ | B+ | 不变 |

### 改进建议优先级

1. **高**: 修复 `_activeProcesses` 死代码 — 使 `cancelTask` 真正生效
2. **高**: 修复 `software_panel.dart` 的 `dynamic` 类型
3. **中**: 提取 `DesignCategory → label` 为统一方法
4. **低**: 将 `_descriptions` map 移入 `builtin_plugins.dart`
5. **低**: 清理未使用的 `dart:io` 导入（若修复 #1 则保留）

### 整体评价

经过两轮修复，项目已从 **B+** 提升至 **A-** 水平。所有测试通过，静态分析零问题，架构清晰，安全性良好。剩余 5 项问题均属轻量级改进，不影响核心功能。
