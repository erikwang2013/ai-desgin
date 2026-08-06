# 审查报告 — 2026-08-06 (v18) — 第三轮问题修复

## 执行摘要

针对「修复所有问题，不要产生新的问题」的第三轮全库扫描，发现 4 个问题（3 个 P2 核心逻辑、1 个 P3 UI），全部修复。72/72 测试通过（新增 2 个取消语义测试），`dart analyze` 零问题。

## 测试结果

```
flutter test            → 72 passed, 0 failed
dart analyze lib test   → No issues found
```

## 已修复问题（4 个）

| # | 级别 | 问题 | 修复 |
|---|------|------|------|
| 1 | P2 | CCRunner 超时/异常后子进程未 kill（`Future.wait` 120s 超时抛错只从 map 移除，Claude CLI 进程成为僵尸进程继续运行） | catch 分支改为 `_processes.remove(key)?.kill()`，超时与异常均终止子进程 |
| 2 | P2 | 排队任务取消无效且产生幽灵记录：① `cancelTask` 不处理队列条目，任务仍会执行、completer 永不完成（调用方挂起）；② pending 占位记录与最终 running 记录 id 不同，`_tasks` 永久残留 pending 幽灵，pruneTasks 也不修剪 | `_QueuedTask` 携带 `pendingId`，排队任务复用同一 record id；`cancelTask` 从队列移除条目并完成 completer |
| 3 | P2 | 运行中任务取消被覆盖：`cancelTask` kill 进程后 submitTask 继续执行，最终以 completed/failed 覆盖 cancelled 状态；且取消已完成任务会改写历史记录 | submitTask 在 `plugin.execute` 后与 catch 分支检查 `status == cancelled` 提前返回；`cancelTask` 对 completed/failed 记录 no-op |
| 4 | P3 | 过滤 Chip 用翻译后的 label 字符串判断 filter key（`_buildChip` 比较 `all`/`inProgress` 文案），翻译变化即失效 | 改为显式传 key，`onSelected` 直接设 `_filterKey` |

## 附带修复

- `app.dart`：新增 `_resolveSoftware()` —— 若当前软件已在市场被卸载，提交时回退到当前领域第一个可用插件，避免「Software not found」失败。
- `TaskOrchestrator` 新增公开 `tasks` getter（任务列表只读视图，供 dashboard 与测试使用）。

## 新增/重写测试（70 → 72）

| 测试 | 覆盖 |
|------|------|
| cancelTask removes a queued task and completes its future | 排队任务取消：状态 cancelled、future 完成不挂起、队列不再执行、无幽灵记录 |
| cancelTask cancels a running task without overwriting its record | 运行中任务取消：最终状态 cancelled 不被 execute 结果覆盖 |
| cancelTask does not overwrite completed history | 终态记录取消为 no-op（原测试断言的旧错误行为已修正） |

新增 `GatedEchoPlugin`（Completer 门控 execute）用于在任务执行中途安全地观察并取消。

## 版本与文档

- 版本保持 1.4.0（本轮无版本变更）。
- README / README_EN：测试数量同步为 72，审查报告链接更新为 v18。
- 无图片需更新（README 架构图为 ASCII，应用图标与支付图标与本轮无关）。
