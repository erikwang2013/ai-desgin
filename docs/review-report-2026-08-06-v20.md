# Review Report 2026-08-06 v20 — Full Test & Deep Inspection

## 验证结果

| 检查 | 命令 | 结果 |
|------|------|------|
| 静态分析 | `flutter analyze` | ✅ No issues found (9.5s) |
| 全部测试 | `flutter test` | ✅ 79/79 passed |
| Rust 检查 | `cargo check` + `cargo clippy` | ✅ 通过，无警告 |
| 审查范围 | 全部 13 个核心/UI/插件文件 + Rust IPC | 见下方发现 |

## v19.1 回归确认

| v19.1 修复 | 回归验证 |
|------------|----------|
| 60s 周期空闲回收（懒启动/自停/dispose 取消） | ✅ 测试 + 代码复查通过；定时器固定 60s 与 `idleTimeoutSeconds` 解耦属文档明示行为，`createSession` 即时检查兜底 |
| 淘汰会话时 cancel 关联任务进程 | ✅ evict/dispose 均取消 tracked taskKey；execute 完成后安全移除（session 已淘汰时无害） |
| FreeCAD 路径改环境变量 | ✅ `os.environ["AI_DESIGN_SCRIPT"]` 无插值 |
| ModelRouter 关键词可配置 | ✅ YAML 缺省=原硬编码值 |
| 7 个新增测试 | ✅ 全部通过（含 off-by-one、fake CLI 杀进程验证） |
| API key 明文（已知限制） | ⚠️ 维持文档化处理（环境无 libsecret，无法引入 secure_storage），未变 |
| flutter_lints ^6 | ✅ analyze 无告警 |

## 发现（按严重度）

### P2

无新增 P2。v19.1 的进程泄漏 / 空闲回收问题均已生效；凭据明文存储为已文档化已知限制，本次复查确认环境限制依然成立（无 libsecret、无 Linux 构建目标、测试环境触发 MissingPluginException）。

### P3（可优化）

1. **设置页表单无验证**（`lib/ui/settings_view.dart`）
   - ModelConfigPage（:192-214）：endpoint 无 URL 格式校验、API key 无非空/格式校验、model 无校验。
   - ProxySettingsPage（:297-312）：port 虽设 `keyboardType: number` 但可粘贴任意文本，无数字/范围（0-65535）校验；畸形 port 会拼出无效 proxy URL（如 `http://host:abc`）写入 `CCRunner.proxyEnvironment`。
   - 项目 CLAUDE.md 要求「Validate input at system boundaries」，设置页即用户输入边界。

2. **CCRunner.cancel 全量分支无覆盖**（`lib/core/cc_runner.dart:73-76`）
   `key == null` 时全量 kill 并清空 map 的分支无调用方（CCProcessManager 总传 key）、无测试。低风险，但若未来有全量取消需求时该分支未经测试验证。

3. **数据归类瑕疵**（`lib/core/builtin_plugins.dart:114,116`）
   `tinkercad` 与 `meshy` 的 `scriptLanguage` 为 `'rest'`（非脚本语言）。功能不受影响（无本地命令时回退「脚本已生成」提示），仅数据归类不严谨。

## 检查过但排除的问题

| 候选 | 结论 |
|------|------|
| `_loadSaved` 不设 CCRunner 静态 → 重启不一致 | ✅ 排除：`app.dart:133-150` 启动时已从 prefs 恢复 endpoint/key/proxy/model |
| 清空保存会破坏运行 | ✅ 排除：`cc_runner.dart:130-131` 对 apiBaseUrl/apiAuthToken 有 `isNotEmpty` 保护，空值安全 |
| TaskDashboard 历史与 initialTasks 重复 | ✅ 排除：`app.dart:300` 仅传 sessionStore，initialTasks 恒为 null |
| plugin_marketplace `cast<DesignPlugin?>` 别扭写法 | ✅ 排除：`firstWhere` orElse 返回 null 需该 cast，写法正确 |
| 定时器 60s 与超时阈值不同步 | ✅ 排除：文档已明示「每 60 秒巡检」，且 createSession 即时检查兜底 |

## 结论

整体健康：analyze / test / clippy 全绿，v19.1 全部修复回归通过，无 P1/P2 级问题。剩余 3 个 P3 均为非紧急优化（表单校验、一个无覆盖分支、数据归类）。测试缺口从 v19 的 6 处收敛到 1 处。

## v20.1 修复记录

| # | 严重度 | 修复内容 | 涉及文件 |
|---|--------|----------|----------|
| 1 | P3 | 设置页表单验证：endpoint 须为合法 http(s) URL、model 字符集校验（字母/数字/`._-`）、proxy port 须为 1-65535 数字、host 不含空格、设 port 必须填 host；失败时红底 SnackBar 报错且不保存不应用；host 保存时自动剥离 `http(s)://` 前缀。API key 允许为空（本地无认证环境，有意设计） | `lib/ui/settings_view.dart`、`test/ui/settings_view_test.dart`（新增 7 个 widget 测试） |
| 2 | P3 | CCRunner.cancel 无 key 全量分支：新增测试用 fake CLI 并发双进程（`echo $$ >> pids`），`cancel()` 后断言两个 PID 均消亡；首版测试轮询竞态已修（先等文件出现再数行数） | `test/core/cc_runner_test.dart` |
| 3 | P3 | tinkercad/meshy 的 `scriptLanguage` 由 `'rest'`（非脚本语言）改为 `'python'` | `lib/core/builtin_plugins.dart` |

验证：`flutter analyze` 无问题；`flutter test` 79 项原有 + 8 项新增（7 settings + 1 cancel）共 87/87 全绿；Rust 无改动。
