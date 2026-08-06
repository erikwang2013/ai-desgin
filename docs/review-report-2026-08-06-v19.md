# Review Report 2026-08-06 v19 — Full Test & Deep Inspection

## 验证结果

| 检查 | 命令 | 结果 |
|------|------|------|
| 静态分析 | `flutter analyze` | ✅ No issues found (8.1s) |
| 全部测试 | `flutter test` | ✅ 72/72 passed |
| Rust 检查 | `cargo check` + `cargo clippy` | ✅ 通过，无警告 |
| 审查范围 | 10 个核心文件 + Rust IPC | 见下方发现 |

## 发现（按严重度）

### P2（建议修复）

1. **空闲会话回收名不符实 — 仅按需触发**
   `lib/core/cc_process_manager.dart:39` 的 `_evictIdleSessions()` 只在 `createSession()` 时调用，没有周期定时器。若应用闲置（无新任务），超过 300s 的过期 session 永不回收，内存占用持续。文档与生命周期图宣称「Idle sessions evicted after 300 s / Timeout 300 s」暗示自动清理。建议加一个周期定时器（如每 60s 检查一次）。

2. **会话淘汰不终止关联的 Claude 进程 — 与文档「防止进程泄漏」不符**
   `createSession` 满 3 个时（cc_process_manager.dart:41-45）仅从 map 移除最旧 CCSession，从不 kill 其关联进程。而 TaskOrchestrator 持有共享 `CCRunner`（task_orchestrator.dart:30,51），进程按 taskKey 存活到自身 120s 超时。被淘汰会话若仍有任务运行中，Claude 进程会继续消耗资源。要么在淘汰时调用 runner 清理，要么修正文档措辞（当前防泄漏实际依赖 CCRunner 的超时/cancel，与 eviction 无关）。

3. **API key 明文存储在 SharedPreferences**
   无加密、无安全存储（flutter_secure_storage）。安全架构图宣称的安全机制未覆盖本地凭据。建议切换 secure storage 或至少文档明确此风险。

### P3（可优化）

4. **FreeCAD 参数插值脆弱**（local_script_executor.dart）
   `'-c', 'exec(open(r"$scriptPath", encoding="utf-8").read())'` 把临时路径插入 Python 源码。Process.start 用参数数组无 shell 注入风险，但路径含引号/反斜杠（Windows）会执行失败。建议改传环境变量或 `sys.argv`。

5. **ModelRouter 关键词硬编码**
   `_inferComplexity`（model_router.dart:100-125）中英关键词列表硬编码，与已配置化的 `config/model-routing.yaml` 风格不一致。可接受，但后续扩展需改代码。

6. **测试缺口**
   72 个测试全过，但以下分支无覆盖：CCRunner 120s 超时 kill 分支、cancel 全量/按 key、PluginManager.dispose 顺序、SessionStore LIKE 转义、淘汰策略。

7. **依赖可升级**
   `flutter pub outdated` 提示 12 个包有更新（flutter_lints 3.0.2→6.0.0、intl 0.20.2→0.20.3 等），版本约束导致不可自动升级。非紧急。

## 结论

整体健康：analyze / test / clippy 全绿，v18 修复（CCRunner kill、取消语义）均生效。主要问题集中在「会话生命周期」实现与文档/图表的偏差（P2 #1 #2），以及凭据明文存储（P2 #3）。无 P1 级问题。

## v19.1 修复记录

| # | 严重度 | 修复内容 | 涉及文件 |
|---|--------|----------|----------|
| 1 | P2 | 空闲回收改为每 60 秒周期巡检（懒启动、空时自停、dispose 取消）；会话淘汰时同步 cancel 关联任务进程（按 session 跟踪 taskKey） | `lib/core/cc_process_manager.dart`、`lib/app.dart`（dispose 装配） |
| 2 | P2 | 同 #1（淘汰即终止进程）；文档/图表述已同步为「每 60 秒巡检 · 回收时终止关联任务进程」 | `docs/diagrams/lifecycle-zh/en.svg`、README 两版 |
| 3 | P2 | 无法引入 flutter_secure_storage（本机无 libsecret、无 Linux 构建目标、测试环境会 MissingPluginException）——已按报告备选方案在文档与图中明确「明文存储为已知限制，建议迁移 Keychain/DPAPI」 | `docs/diagrams/security-zh/en.svg`、README 两版 |
| 4 | P3 | FreeCAD 脚本路径改经环境变量 `AI_DESIGN_SCRIPT` 传入，消除字符串插值脆弱性 | `lib/core/local_script_executor.dart` |
| 5 | P3 | 复杂度推断关键词可经 `config/model-routing.yaml` 的 `keywords: {simple, creative}` 段配置（缺省=原硬编码值） | `lib/core/model_router.dart`、`config/model-routing.yaml` |
| 6 | P3 | 新增 7 个测试：淘汰杀进程、空闲回收（含 off-by-one 修正）、dispose 清理、CCRunner 超时杀进程（fake CLI 验证 PID 消亡）、LIKE 转义、disposeAll 顺序、keywords 覆盖 | `test/core/cc_process_manager_test.dart`、`cc_runner_test.dart`、`session_store_test.dart`、`plugin_manager_test.dart`、`model_router_test.dart` |
| 7 | P3 | `flutter_lints ^3→^6` 升级成功（analyze 仅 1 处 info，已修 `use_null_aware_elements`）；`intl` 无法升级（Flutter SDK 锁定 0.20.2），已回退并记录 | `pubspec.yaml`、`lib/core/cc_runner.dart` |

验证：`flutter analyze` 无问题；`flutter test` 72 项原有 + 7 项新增全绿；Rust 无改动。
