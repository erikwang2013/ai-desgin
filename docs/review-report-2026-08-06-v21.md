# Review Report 2026-08-06 v21 — Full Test & Deep Inspection

## 验证结果

| 检查 | 命令 | 结果 |
|------|------|------|
| 静态分析 | `flutter analyze` | ✅ No issues found (8.1s) |
| 全部测试 | `flutter test` | ✅ 87/87 passed |
| Rust 检查 | `cargo check` + `cargo clippy` | ✅ 通过，无警告 |
| 审查范围 | 全部核心/UI/模型文件 + v19.1/v20.1 回归 | 见下方发现 |

## v20.1 回归确认

| v20.1 修复 | 回归验证 |
|------------|----------|
| 设置页表单验证（endpoint/model/port/host） | ✅ 7 个 widget 测试通过；validate→error→不保存链路正确 |
| CCRunner.cancel 全量分支测试 | ✅ 双进程 fake CLI 测试通过（轮询竞态已修） |
| tinkercad/meshy scriptLanguage → python | ✅ smoke 测试通过 |
| v19.1 全部修复 | ✅ 继续生效（60s 回收、淘汰杀进程、环境变量、keywords 可配） |

## 发现（按严重度）

### P2

无新增 P2。

### P3（可优化）

1. **取消任务后本地脚本仍会执行一次**（`lib/core/task_orchestrator.dart:101-116`）
   `cancelTask` 会 `_ccRunner.cancel(key)` 杀掉 Claude CLI 进程，但 `executeWithClaude` 返回的是 failure 结果（非异常），流程继续：`generatedScript` 保持任务原文 → `plugin.execute()` 仍在本地执行（blender/freecad/openscad 会真实运行脚本），直到第 114 行才检查 cancelled 状态。建议把 cancelled 检查移到 `executeWithClaude` 返回后、`plugin.execute` 之前，取消后跳过本地执行。

2. **软件下拉选项缓存不失效**（`lib/app.dart:274`）
   `_cachedOptions.putIfAbsent(domain, ...)` 按领域缓存软件列表；用户在插件市场卸载插件后缓存陈旧，ChatView 下拉框仍显示已卸载软件。UI 有 fallback（选中 id 不在列表时回退首个，不崩溃），但列表与真实状态不一致。建议在插件变更处（marketplace 卸载/安装）清缓存。

## 检查过但排除的问题

| 候选 | 结论 |
|------|------|
| CCRunner 超时后进程泄漏 | ✅ 排除：catch 分支（cc_runner.dart:186-190）kill 并清理 map，timeout 测试已验证 PID 消亡 |
| LocalScriptExecutor 全局缓存 TTL 覆盖多插件 | ✅ 排除：`_availableCache.containsKey(pluginId)` 按插件兜底，未缓存键会重新探测 |
| FreeCAD 环境变量路径（v19.1） | ✅ 排除：`os.environ["AI_DESIGN_SCRIPT"]` 无字符串插值 |
| models 结构 / locale_provider / software_panel | ✅ 干净，无问题 |
| TaskOrchestrator pruneTasks 顺序 | ✅ 排除：先释放槽位再处理队列再修剪，顺序正确 |

## 结论

整体健康：analyze / test / clippy 全绿，v20.1 修复全部回归通过，无 P1/P2 级问题。剩余 2 个 P3：取消任务后本地脚本仍执行一次（行为瑕疵）、软件选项缓存陈旧（UI 一致性问题）。均为非紧急优化。

## v21.1 修复记录

| # | 严重度 | 修复内容 | 涉及文件 |
|---|--------|----------|----------|
| 1 | P3 | 取消任务后跳过本地脚本执行：cancelled 检查移到 `executeWithClaude` 返回后、`plugin.execute` 之前（取消发生在 Claude 生成阶段时，CLI 进程被杀、`generated` 为 failure，不再继续跑 blender/freecad/openscad 等本地脚本），并保留 `plugin.execute` 之后的双保险检查（取消发生在本地执行期间时不覆盖 cancelled 记录）。修复过程中首版仅保留前置检查导致「running 任务取消后记录被 completed 覆盖」回归，已通过补回后置检查解决 | `lib/core/task_orchestrator.dart`、`test/core/task_orchestrator_test.dart`（新增 1 个测试：GatedFakeCCRunner 阻断生成 + CountingEchoPlugin 计数，断言 `executeCalls == 0`） |
| 2 | P3 | 软件下拉选项缓存按插件 id 签名失效：`_buildSoftwareOptions()` 以 `plugins.map((p) => p.id).join(',')` 为指纹，插件集变化（市场卸载/安装）时自动重建缓存，下拉框不再显示已卸载软件 | `lib/app.dart` |

验证：`flutter analyze` 无问题；`flutter test` 88/88 全绿（87 项原有 + 1 项新增）；`cargo check` + `cargo clippy` 通过，Rust 无改动。
