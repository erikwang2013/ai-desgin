# Review Report 2026-08-06 v22 — Full Test & Deep Inspection

## 验证结果

| 检查 | 命令 | 结果 |
|------|------|------|
| 静态分析 | `flutter analyze` | ✅ No issues found (15.0s) |
| 全部测试 | `flutter test` | ✅ 88/88 passed |
| Rust 检查 | `cargo check` + `cargo clippy` | ✅ 通过，无警告 |
| 审查范围 | 全部 UI 文件（chat/dashboard/marketplace/shell/software_panel）+ v21.1 回归 | 见下方发现 |

## v21.1 回归确认

| v21.1 修复 | 回归验证 |
|------------|----------|
| 取消任务跳过本地脚本（前置检查）+ 执行后双保险（不覆盖 cancelled） | ✅ 新增测试 `cancelling a running task skips local script execution` 通过；原 running-cancel 测试不再回归（88/88 含两者） |
| 软件下拉选项按插件 id 签名失效 | ✅ 代码复查：`_cachedOptionsSignature` 比对签名，插件集变化即重建 |

## 发现（按严重度）

### P2

1. **重启后已卸载插件从市场消失，无法重新安装**（`lib/ui/plugin_marketplace.dart:61-80`）
   `_loadUninstalled` 从 prefs 恢复卸载状态后执行 `_plugins = _buildPluginsFromManager()`，而该方法只映射 `pluginManager.getAll()`（当前已注册插件）——被卸载插件被整体排除出列表，「Available」区为空。同会话内卸载会保留列表条目并显示 Install 按钮（`_toggleInstall` 走 idx 更新），重启后该条目彻底消失，无任何重装入口。
   现有测试甚至固化了该行为：`test/ui/plugin_marketplace_test.dart:64-65` 断言 `find.text('Sketch'), findsNothing`。
   建议：`_buildPluginsFromManager` 合并 `_removedPlugins`（及 builtInPlugins 中未注册者）为 `installed: false` 条目，修复后同步更新上述测试为「Sketch 出现在 Available 区」。

### P3（可优化）

1. **App 启动不恢复插件卸载状态**（`lib/app.dart:110-112`）
   `_initOrchestrator` 无条件注册全部 builtin 插件；重启后已卸载插件仍出现在软件下拉、任务执行与连接探测中，直到用户打开市场页才被 `_loadUninstalled` 从共享 manager 移除。建议启动时读取 `uninstalled_plugin_ids` 并跳过注册（顺带省掉已卸载插件的 `LocalScriptExecutor` 探测）。

2. **cancelTask 无 UI 入口**（`lib/core/task_orchestrator.dart:176`，lib 内无调用方）
   任务仪表盘对 running/pending 任务仅显示图标，无取消按钮；聊天面板提交后亦无取消操作。v21.1 刚修复的取消链路（跳过本地执行、不覆盖记录）在 UI 中不可达。建议 dashboard 卡片对 running/pending 加取消按钮回调 `orchestrator.cancelTask`。

## 检查过但排除的问题

| 候选 | 结论 |
|------|------|
| chat_view 消息上限 / 无 onSubmit 回退 | ✅ 排除：500 条裁剪、echo 兜底、catchError 有 mounted 保护 |
| TaskDashboard 历史与实时任务重复 | ✅ 排除：IndexedStack 急切构建 + `_restoreHistory` 仅 initState 一次；随后任务走 addTask |
| shell 导航 label / 领域切换 | ✅ 排除：label 数组回退安全，切换有 lastSoftware 记忆 |
| software_panel 插件列表陈旧 | ✅ 排除：实时读 `pm.getAll()`，无缓存 |
| 市场 in-session 卸载/重装 | ✅ 排除：同会话内可正常往返（Install/Uninstall 双向可用），仅跨会话路径坏 |
| settings_view（v20.1 修复） | ✅ 排除：7 个 widget 测试回归通过 |
| v21.1 双守卫互相干扰 | ✅ 排除：前置检查跳过本地执行，后置检查仅防覆盖，两条路径测试均绿 |

## 结论

整体健康：analyze / test / clippy 全绿，v21.1 修复全部回归通过。新发现 1 个 P2（重启后卸载插件从市场消失、无法重装，且被现有测试固化）与 2 个 P3（启动不恢复卸载状态、cancel 无 UI 入口）。其中 P2 为功能缺陷，建议优先修复。

## v22.1 修复记录

| # | 严重度 | 修复内容 | 涉及文件 |
|---|--------|----------|----------|
| 1 | P2 | 重启后卸载插件不再从市场消失：`_buildPluginsFromManager` 合并 `_removedPlugins`（以及 builtInPlugins 中未注册者）为 `installed: false` 条目，「Available」区持续可列出、可重装。重写 `Uninstall persists across marketplace instances` 测试：第二个 marketplace 实例中 Sketch 出现在 Available 区（`scrollUntilVisible` 滚到下方区块），点 Install 可恢复。修复过程中发现两个测试陷阱并解决：① `ListView(children:)` 是 sliver，视口外 children 不挂载——旧断言 `findsNothing` 是「因未挂载而找不到」，错误通过；② 卸载时弹出的 snackbar（2s）遮住底部 Install 按钮导致 `tester.tap` 未命中——先 `pump(3s)` 让 snackbar 过期再点击 | `lib/ui/plugin_marketplace.dart`、`test/ui/plugin_marketplace_test.dart` |
| 2 | P3 | App 启动恢复插件卸载状态：`_initOrchestrator` 启动时读取 `uninstalled_plugin_ids`，已卸载插件不再注册（软件下拉、任务执行、连接探测一并跳过），无需等打开市场页才生效 | `lib/app.dart` |
| 3 | P3 | cancelTask 补 UI 入口：dashboard 任务卡片对 running/pending（且提供 onCancel 时）显示取消按钮（Icons.close，tooltip 本地化），点击回调 `orchestrator.cancelTask` 并本地标记 cancelled；新增 `cancel` 键到 12 个 ARB 文件并 `flutter gen-l10n` 重新生成。新增 3 个 widget 测试（running 显示并可取消 / pending 显示 / completed 不显示） | `lib/ui/task_dashboard.dart`、`lib/l10n/app_*.arb`（12 个）、`lib/l10n/app_localizations.dart`（重新生成）、`test/ui/task_dashboard_test.dart`（新增） |

验证：`flutter analyze` 无问题；`flutter test` 91/91 全绿（88 项原有 + 3 项新增 dashboard 测试；marketplace 测试重写后通过）；`cargo check` + `cargo clippy` 通过，Rust 无改动。
