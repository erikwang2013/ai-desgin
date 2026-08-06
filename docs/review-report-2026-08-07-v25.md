# Review Report 2026-08-07 v25 — Full Test & Deep Inspection

## 验证结果

| 检查 | 命令 | 结果 |
|------|------|------|
| 静态分析 | `flutter analyze` | ✅ No issues found (9.4s) |
| 全部测试 | `flutter test` | ✅ 101/101 passed（99 + 2 个新回归测试） |
| Rust 检查 | `cargo check` + `cargo clippy` | ✅ 通过，0 错误 0 警告（本轮未改动 Rust，沿用上轮验证） |
| 审查范围 | Dart 全量（core 层 + 全部 UI 文件）+ 测试覆盖核对 | 见下方发现 |

## 发现（按严重度）

本轮主题：**取消链路与连接探测的 UI/持久化一致性**。全部为 P3。

1. **取消的任务被当失败显示**（`lib/app.dart` `_onSubmit`）
   返回消息只区分 `completed` 与「其余全部当失败」——被取消的任务显示「❌ Task failed: Unknown error」，与任务实际状态（cancelled）矛盾，误导用户。

2. **软件面板连接状态无刷新入口**（`lib/app.dart` 启动探测 + `lib/ui/software_panel.dart`）
   连接探测只在启动执行一次（`_initOrchestrator` 内联）。软件启动/关闭/安装后，面板状态保持陈旧，只能重启应用刷新。

3. **取消的任务不落库**（`lib/core/task_orchestrator.dart` `cancelTask`）
   `session.addRecord` 只在任务完成/失败时调用；`cancelTask` 仅更新内存 `_tasks`。取消的任务重启后从仪表盘历史消失，与完成/失败任务的行为不一致。

## 修复记录（v25.1）

| # | 问题 | 严重度 | 修复 | 文件 |
|---|------|--------|------|------|
| 1 | 取消任务显示失败 | P3 | `_onSubmit` 增加 `cancelled` 分支，返回「⚠️ \<task\> — Cancelled」（复用现有 `cancel` l10n 键，不新增键） | `lib/app.dart` |
| 2 | 连接状态无刷新 | P3 | 启动探测提取为 `_runConnectionProbes()`（初始化与刷新复用）；`SoftwarePanel` 新增可选 `onRefresh` 回调 + 标题栏刷新按钮（无 `onRefresh` 时不显示，向后兼容） | `lib/app.dart`、`lib/ui/software_panel.dart` |
| 3 | 取消任务不落库 | P3 | `cancelTask` 两个分支（queued/running）统一调用新增 `_recordCancelledInSession()`，以 `cancelled` 状态写入会话历史；`app.dart` 新增 `_cancelAndPersist` 包装 cancelTask + `SessionStore.save`（fire-and-forget，catchError 防未处理异常） | `lib/core/task_orchestrator.dart`、`lib/app.dart` |

### 回归测试（+2）

- `task_orchestrator_test.dart`：`cancelTask records cancelled entry in session history` — 取消 running 任务后，会话历史含 1 条 `cancelled` 记录且任务文本正确。
- `software_panel_test.dart`：`refresh button re-runs connection probes`（点击刷新按钮触发回调）+ `hides refresh button without onRefresh`（无回调时不渲染按钮）。

## 检查过但排除的问题

| 候选 | 结论 |
|------|------|
| LocalScriptExecutor 探测缓存 60s 全局滑动窗口 | ✅ 排除：行为正确（未探测过的插件总是真实探测），仅轻微低效，不值得为缓存窗口复杂度付费 |
| running/pending 任务不落库 | ✅ 排除：重启后进程无法恢复执行，落库无意义；v19 起即为此设计 |
| `session_store.save` 仅增量插入（同 id 记录不更新） | ✅ 排除：orchestrator 每次 addRecord 生成新 uuid，语义为追加历史，无覆盖需求 |
| cc_runner / settings_view / chat_view / plugin_marketplace / model_router | ✅ 全部复查，无新问题（超时 kill、校验、回滚保护均已就位） |
| l10n 新增键 | ✅ 未引入（tooltip 用字面量、cancelled 分支复用 `cancel` 键），保持 en/zh 等 15 语言文件同步现状 |
| Rust 层 | ✅ 本轮零改动，v24 超时修复（23 处）继续有效，workspace 仅 3 处 spawn 且均有超时/kill 兜底 |

## 结论

整体健康：analyze / test 全绿，101/101 测试通过。本轮把「取消任务」和「连接状态」两条链路补成闭环：取消不再误报失败、取消结果跨重启保留、连接状态可手动刷新——三处均为 P3 一致性修复，无新依赖、无 l10n 改动，改动集中在 app.dart / software_panel.dart / task_orchestrator.dart 三文件 + 2 个回归测试。

## 技术说明

- `_recordCancelledInSession` 仅对已存在的会话写入（queued 任务取消时会话可能尚未创建，此时跳过——内存中 cancelled 记录仍完整）。
- 刷新按钮点击为 fire-and-forget（`onPressed: () => widget.onRefresh!()`），探测内部含 5s 超时，不会挂起 UI。
- `_cancelAndPersist` 的 `save` 失败静默（`catchError`），与 `_onSubmit` 中 save 的容错语义一致。
