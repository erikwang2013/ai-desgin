# AI Design Studio — 综合审查报告

**版本**: v1.0.7
**日期**: 2026-07-31（原始报告）· 第二轮更新: 2026-08-01 · 第三轮: 2026-07-31（本次）
**分支**: main
**审查范围**: Flutter (Dart) + Rust 全项目

---

## 当前构建与测试状态

| 检查项 | 状态 |
|--------|------|
| `flutter analyze` | **0 issues** |
| `flutter test` | **45/47 passed** (2 failures) |
| `cargo build` | 22 crates 通过 |
| `cargo clippy` | **0 warnings** |
| Dart 源文件 | 20 个 (~2058 行) |
| Rust 插件 | 21 个 + core crate |

---

## 第三轮审查发现 (2026-07-31)

### 一、测试失败 (2 项) [P0]

#### 1.1 `cancelTask cancels a pending task` — 竞态条件

**文件**: `test/core/task_orchestrator_test.dart:67`

**根因**: EchoPlugin.execute() 同步完成返回。`cancelTask()` 被调用时任务已处于 `completed` 状态。`cancelTask()` 只检查 `!= TaskStatus.cancelled`，未判断是否处于可取消状态。

**修复**: `task_orchestrator.dart:114` 的状态检查应改为只允许取消 pending/running 状态的任务。

#### 1.2 `session is created per software and records history` — 超时

**文件**: `test/core/task_orchestrator_test.dart:60`

**根因**:
1. `CCRunner.isAvailable()` 调用 `Process.run('claude', ['--version'])`，系统中 claude 不可用时阻塞至 30 秒测试超时
2. 重试后 session.history.length 为 0 — 可能是异常路径中 `addRecord` 未被调用

**修复**: `isAvailable()` 需要添加进程超时（Duration(seconds: 5)）。测试应注入 `CCRunner(claudeCliPath: '/nonexistent')`。

---

### 二、静默错误吞没 (5 处) [P1]

| 文件:行号 | 场景 | 风险 |
|-----------|------|------|
| `app.dart:92` | 数据库初始化失败 | 用户无感知，app 无持久化运行 |
| `app.dart:146` | Session 保存失败 | 任务历史丢失 |
| `task_orchestrator.dart:64` | Claude CLI 调用失败 | 静默降级为用户原始文本 |
| `cc_runner.dart:108` | JSON 行解析失败 | 可能丢失有效返回 |
| `session_store.dart:147` | 上下文 JSON 反序列化失败 | 返回空 SessionContext |

**建议**: 最低限度添加 `_log.warning()`。`app.dart:92` 和 `task_orchestrator.dart:64` 应通过 UI 通知用户。

---

### 三、代码质量问题 (4 项) [P2]

#### 3.1 硬编码模型名称

`'claude-sonnet-4-6'`、`'claude-opus-4-7'`、`'claude-haiku-4-5'` 散布在 `lib/app.dart:68-77`、`lib/core/model_router.dart:24` 及 4 个测试文件中。

**建议**: 定义 `ModelNames` 常量类，复用 `version.dart` 的集中管理模式。

#### 3.2 `_connectionStatus` 写入后永不再更新

`lib/app.dart:96-98` 将所有插件状态初始化为 `false`，但没有任何代码执行实际的连接检查。`SoftwarePanel` 永远显示「未连接」。

#### 3.3 SoftwarePanel 插件列表不完整

`lib/ui/software_panel.dart:_defaultSoftware` 只有 8 项，缺少 **Fusion 360**（`lib/app.dart:_builtInPlugins` 有 9 项）。两端列表应从同一数据源派生。

#### 3.4 `CCRunner.isAvailable()` 无缓存

每次 `submitTask()` 都 spawn `claude --version` 进程。应缓存首次检查结果。

---

### 四、优化建议 (3 项) [P3]

#### 4.1 输入验证缺失

`TaskOrchestrator.submitTask()` 未验证 task 参数：空字符串、纯空白、超长文本。

#### 4.2 ChatView 消息上限

`_maxMessages = 500` 对纯内存存储偏高。建议降低或增加粗略字节数估算。

#### 4.3 Rust 插件未通过 flutter_rust_bridge 集成

`rust/plugins/` 下 21 个 Rust 插件遵循统一的 `DesignPlugin` trait，但与 Dart 侧 `BuiltInPlugin` 完全独立。需验证 `flutter_rust_bridge` 桥接链路是否打通。

---

### 五、测试覆盖缺口

| 组件 | 文件 | 优先级 |
|------|------|--------|
| CCRunner.execute() | `lib/core/cc_runner.dart` | P1 — 核心执行路径 |
| TaskDashboard | `lib/ui/task_dashboard.dart` | P2 |
| SettingsView | `lib/ui/settings_view.dart` | P3 |
| SoftwarePanel | `lib/ui/software_panel.dart` | P3 |

---

### 六、正面评价

- **静态分析零问题** — 代码风格统一
- **核心逻辑测试覆盖较全** — PluginManager、ModelRouter、SessionStore、TaskOrchestrator
- **架构分层清晰** — models / core / ui / plugin_sdk 职责分明
- **版本号集中管理** — `lib/core/version.dart` 作为单一真相源
- **数据库设计合理** — 索引、外键、批量事务写入已考虑
- **无 TODO/FIXME/HACK** — 代码库干净，无遗留标记
- **Rust 插件模式一致** — 21 个插件均遵循相同的 trait + script.rs 模式

---

## 第二轮修复历史 (2026-08-01) — 14 项

已修复：插件注册、并发竞态、Meshy 路由、SessionStore 集成、超时处理、版本号统一等。详见 `review-report-2026-08-01.md`。

## 第一轮修复历史 (2026-07-31) — 14 项

已修复：P0 bridge 生成 / ChatView 对接 / Tab 切换、P1 执行路径 / Session 状态等。详见 git 提交记录。

---

## 本轮修复优先级总览

| 优先级 | 条目 | 预估工时 |
|--------|------|---------|
| P0 | 修复 2 个测试失败 | 30 min |
| P1 | 静默吞错添加日志 | 20 min |
| P1 | `isAvailable()` 添加进程超时 | 10 min |
| P2 | 模型名称常量化 | 10 min |
| P2 | 统一插件列表数据源 | 15 min |
| P3 | 输入验证 | 10 min |
| P3 | 补充 UI 组件测试 | 2 h |
