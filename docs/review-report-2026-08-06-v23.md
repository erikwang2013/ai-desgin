# Review Report 2026-08-06 v23 — Full Test & Deep Inspection

## 验证结果

| 检查 | 命令 | 结果 |
|------|------|------|
| 静态分析 | `flutter analyze` | ✅ No issues found (21.9s) |
| 全部测试 | `flutter test` | ✅ 91/91 passed |
| Rust 检查 | `cargo check` + `cargo clippy` | ✅ 通过，无警告 |
| 审查范围 | 全部 core 模块（orchestrator/cc_runner/process_manager/model_router/session_store/executor/plugin_manager）+ settings_view + Rust 侧 | 见下方发现 |

## v22.1 回归确认

| v22.1 修复 | 回归验证 |
|------------|----------|
| 市场重建合并已卸载插件（P2） | ✅ 91/91 含重写后的 `Uninstall persists across marketplace instances`（滚动 + snackbar 过期处理） |
| App 启动恢复卸载状态（P3） | ✅ 代码复查：`_initOrchestrator` 注册前读取 `uninstalled_plugin_ids` 并跳过 |
| dashboard 取消按钮 + 12 ARB（P3） | ✅ 3 个新 widget 测试通过；`flutter gen-l10n` 产物无 analyze 问题 |

## 发现（按严重度）

### P2

1. **Claude 生成失败时把任务描述当脚本执行**（`lib/core/task_orchestrator.dart:106`）
   `executeWithClaude` 返回 Map，`'script'` 来自 `CCResult.script`；而 `CCResult.failure`（`cc_runner.dart:38`）只带 error、script 为 null，`fromJson` 对缺 `script` 键也不设默认。此时 106 行 `generated['script'] as String? ?? task` 回退为任务原文，119 行 `plugin.execute(generatedScript)` 把「帮我设计一个海报」这种描述文本当脚本执行——API 报错会变成执行任务文字。建议：检查 `generated['success'] == false` 时直接返回 failed 记录，不做回退执行。

2. **`plugin.execute` 异常时 CC 会话泄漏**（`lib/core/task_orchestrator.dart:119-120`）
   `closeSession` 不在 finally 中：本地脚本执行抛异常（如进程崩溃、权限错误）时会话留在进程管理器直到被空闲驱逐或满员驱逐。建议 `try/finally` 包住 execute。

3. **CCRunner 从不检查 CLI 退出码**（`lib/core/cc_runner.dart:143-185`）
   `Process.start` 后只等 stdout/stderr，`exitCode` 未 await。CLI 非零退出（API key 错误、崩溃）只要 stdout 非空，就落到 177 行 raw-output 分支，构造 `CCResult` 时 `success` 默认 true（22 行）——错误文本被当成生成脚本。建议 await `process.exitCode`，非零时返回 failure。

4. **SessionStore 反序列化无容错**（`lib/core/session_store.dart:91,206`）
   `load()` 的 `jsonDecode(context_json)` 与 `_deserializeRecord` 的 `jsonDecode(artifacts_json)`/`DateTime.parse` 均无 try/catch，单条脏数据（手改 DB、旧版本写入、字段缺失）会让整个会话/列表加载抛异常，与 173 行 `_parseContext` 的容错不一致。建议统一捕获并降级跳过该条。

5. **模型路由缺键时路由到 "null" 模型**（`lib/core/model_router.dart:93`）
   `r['model'].toString()`：路由条目缺 `model` 键时得到字面量 `"null"`，任务被路由到不存在的模型；且 96-98 行 catch 仅记日志，中途失败会留下部分已加载的路由（半更新状态）。建议校验 `model` 非空并跳过该条；加载失败时回滚本次加载。

6. **本地脚本超时不杀子进程**（`lib/core/local_script_executor.dart:72`）
   `Process.run().timeout()` 超时仅放弃 Future，挂死的 Blender/FreeCAD 在"超时"后继续运行；finally 中临时目录删除在 Windows 上可能因文件占用失败。建议 `Process.start` + 超时后 `kill()`。（注入风险已排除：非 Windows 不走 shell，freecad 经 env 传递。）

7. **Rust 侧无超时**（`rust/plugins/freecad/src/script.rs:19-30`、`rust/core/src/ipc.rs:30`）
   `Command::output()`/`wait_with_output()` 无超时：FreeCAD 挂起或 stdout 管道写满时 Rust 侧永久阻塞（Dart 侧 120s 超时只放弃 Future，子进程依然在跑）。建议 spawn + 超时后 kill。Rust 主树无 `unwrap()/expect()`，panic 风险低。

### P3（可优化）

1. **stdin 先写后读，管道可能死锁**（`cc_runner.dart:139-141`）：大 prompt + 子进程边读边写进度时 64KB 管道缓冲可能写满，仅靠 120s 超时兜底。建议启动即并发读 stdout。
2. **满员驱逐最旧会话可能杀运行中任务**（`cc_process_manager.dart:74-78`）：`createSession` 满员时驱逐最旧会话，即使它正在执行任务。建议仅驱逐空闲会话。
3. **SessionStore 事务粒度**（`session_store.dart:46-65`）：session insert 在记录事务之外（失败留孤儿行）；`IN (...)` 超过 SQLite 999 变量上限（>999 会话时抛错）；delete 未用事务。
4. **executor 缓存 TTL 不一致**（`local_script_executor.dart:85`）：ProcessException 路径更新 `_availableCache` 却不更新 `_lastCacheCheck`，与正常路径 TTL 计算不一致。
5. **settings_view 异步边界**（`settings_view.dart:156-159,310`）：`_loadSaved` 异步完成时页面可能已 dispose，对已释放 controller 赋值抛错（缺 `mounted` 检查）；代理 host 校验在 normalize 之前，`http://x.com/path` 能通过校验却拼出畸形代理 URL；API key 明文存 SharedPreferences。
6. **initializeAll 快速失败**（`plugin_manager.dart:29-30`）：`Future.wait` 单个插件 init 失败会阻止其余插件并向上抛；`register` 静默覆盖仅 dev.log。

## 检查过但排除的问题

| 候选 | 结论 |
|------|------|
| cc_runner 超时路径孤儿进程 | ✅ 排除：188 行 catch 中 `_processes.remove(...)?.kill()` |
| model_router 空 YAML 崩溃 | ✅ 排除：`doc` 为 null 被 catch 兜住，静默回退默认值 |
| builtin_plugins 诚实回退 | ✅ 排除：slicer `cli` 语言与 `_cliExecutables` 白名单一致 |
| Rust IsolatedProcess 泄漏 | ✅ 排除：Drop kill 兜底 |
| submitTask 排队 completer 泄漏 | ✅ 排除：取消路径由 cancelTask 补全 |
| v22.1 三个修复 | ✅ 排除：见上方回归确认 |

## 结论

整体健康：analyze / test / clippy 全绿，91/91 测试通过，v22.1 修复全部回归通过。本轮聚焦 core 层，新发现 7 个 P2（集中在失败路径处理：生成失败回退执行、会话泄漏、退出码不检查、反序列化容错、模型路由缺键、双端超时缺失）与 6 个 P3。核心主题：**失败路径没有按失败处理**——多数 P2 都是「出错时把错误当正常数据继续走」的模式，建议优先修复 1/2/3（同一条任务执行链上的三个失败路径）。

## v23.1 修复记录

### 验证结果（修复后）

| 检查 | 命令 | 结果 |
|------|------|------|
| 静态分析 | `flutter analyze` | ✅ No issues found |
| 全部测试 | `flutter test` | ✅ 98/98 passed（91 + 7 个新回归测试） |
| Rust 检查 | `cargo check` + `cargo clippy` | ✅ 通过，无警告 |

### 修复清单（13/13）

| # | 问题 | 严重度 | 修复 | 文件 | 回归测试 |
|---|------|--------|------|------|----------|
| 1 | 生成失败回退执行任务文本当脚本 | P2 | `failGenerated` 闭包：关闭 CC 会话、保留取消状态、标记 failed，不再回退 | `lib/core/task_orchestrator.dart` | `task_orchestrator_test.dart`: `failed generation does not execute the task text as a script` |
| 2 | execute 异常时 CC 会话泄漏 | P2 | execute 块 `try/finally` 关闭会话 | `lib/core/task_orchestrator.dart` | 既有取消/失败测试覆盖 |
| 3 | cc_runner 不检查退出码 | P2 | stdin 启动即消费防死锁；`exitCode.timeout()` 后非零返回 failure | `lib/core/cc_runner.dart` | `cc_runner_test.dart`: `execute fails when the CLI exits non-zero even with stdout` |
| 4 | session_store 反序列化不健壮 | P2 | `_parseDate` 容错日期；`_deserializeRecord` try/catch 返回 null；IN 查询按 500 块分块 | `lib/core/session_store.dart` | `session_store_test.dart`: `load tolerates corrupt task records` / `listRecent tolerates corrupt session rows` |
| 5 | model_router "null" model | P2 | 无 model 键的路由跳过并警告；加载失败回滚此前状态 | `lib/core/model_router.dart` | `model_router_test.dart`: `routes without a model key are skipped` / `failed config load rolls back previous routes` |
| 6 | executor 超时不 kill 进程 | P2 | `Process.start` + `exitCode.timeout` + 超时 kill；ProcessException 同步缓存 TTL | `lib/core/local_script_executor.dart` | 既有 timeout 测试覆盖 |
| 7 | Rust 无超时（ipc/freecad） | P2 | 线程 reader + `recv_timeout(120s)` + 超时 kill，替代 `wait_with_output` | `rust/core/src/ipc.rs`, `rust/plugins/freecad/src/script.rs` | cargo check/clippy 通过 |
| 8 | stdin 写入死锁风险 | P3 | stdout/stderr 消费 future 先行启动（与 #3 同一修复） | `lib/core/cc_runner.dart` | 同 #3 |
| 9 | 满员驱逐运行中会话 | P3 | 只驱逐 idle 会话；全忙时抛 StateError | `lib/core/cc_process_manager.dart` | `cc_process_manager_test.dart`: `full manager evicts the idle session, keeping the busy one` / `full manager with all sessions busy refuses a new session` |
| 10 | store 事务粒度 | P3 | save/delete 单事务包裹 | `lib/core/session_store.dart` | 既有测试覆盖 |
| 11 | 缓存 TTL 不一致 | P3 | 与 #6 同一修复 | `lib/core/local_script_executor.dart` | 同 #6 |
| 12 | settings 异步边界 | P3 | `_loadSaved` 补 `mounted` 检查；代理 host 先 normalize 再校验、拒绝含 `/` | `lib/ui/settings_view.dart` | 既有 widget 测试覆盖 |
| 13 | initializeAll 快速失败 | P3 | 单插件 init 失败 try/catch + dev.log，不阻塞其余插件 | `lib/core/plugin_manager.dart` | 既有测试覆盖 |

### 说明

- 全部 13 个问题已修复，验证 98/98 全绿；7 个新回归测试覆盖 4 个 P2 与 1 个 P3（其余由既有测试覆盖）。
- 已知限制（未引入依赖）：API key 明文存 SharedPreferences（记录于 v23 报告 #5 P3），继续沿用。
- 测试期间发现 `cc_runner_test` 中 fake CLI 需先消费 stdin（`cat > /dev/null`）才能走退出码路径；`task_orchestrator` 补 `models/plugin.dart` import（`ScriptResult` 定义于此）。
