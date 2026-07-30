# AI Design Studio — 综合审查报告

**日期**: 2026-07-31  
**分支**: main  
**审查范围**: Flutter (Dart) + Rust 全项目

---

## 一、构建与测试状态

| 检查项 | 状态 | 详情 |
|--------|------|------|
| `flutter analyze` | 3 info 警告 | 无 error/warning 级别问题 |
| `flutter test` | 49 passed | 全部通过 |
| `cargo build` | 通过 | 18 个 crate 编译成功 |
| `cargo test` | 0 个 Rust 单元测试 | 无实质性 Rust 测试 |
| `cargo clippy` | 33+ 警告 | 详见下方 |

---

## 二、问题清单

### P0 — 阻断性问题

#### 2.1 Flutter-Rust Bridge 未生成

`flutter_rust_bridge.yaml` 指向的 `rust/core/src/api.rs` 文件**不存在**。整个 Dart ↔ Rust 互操作层缺失，Dart 端无法调用任何 Rust 代码。

- **影响**: Rust 插件完全不可用
- **修复**: 创建 `rust/core/src/api.rs`，定义 bridge 函数，运行 `flutter_rust_bridge_codegen generate`

#### 2.2 ChatView 核心逻辑被 Mock

`lib/app.dart:50-53` — `onSubmit` 回调始终返回固定字符串，没有实际调用 `TaskOrchestrator`：

```dart
onSubmit: (_) async {
  await Future.delayed(const Duration(seconds: 1));
  return '任务已提交，正在通过 Claude Code 生成脚本...';
},
```

- **影响**: 聊天界面是假功能，无法提交真实任务
- **修复**: 注入 `TaskOrchestrator` 实例并从 `onSubmit` 调用 `submitTask()`

---

### P1 — 重要问题

#### 2.3 Rust 插件缺少单元测试

17 个 Rust 插件 + core，**0 个 Rust unit test**。每个 plugin 的 `new()`、`execute()`、`check_connection()` 等关键方法没有测试覆盖。

#### 2.4 TaskOrchestrator 执行路径不一致

`lib/core/task_orchestrator.dart:44-49` — 先通过 `_ccManager.createSession()` 创建 session 并构建 request，但随后直接调用 `plugin.execute()` 而**未使用** `_ccManager.executeWithClaude()`。`buildRequest()` 的结果被丢弃。

```dart
// buildRequest 的结果未被使用
_ccManager.buildRequest(sessionId: session.id, task: task, model: model);
// 直接调用 plugin.execute，绕过 ccManager
final result = await plugin.execute(task);
```

- **修复**: 应调用 `_ccManager.executeWithClaude()` 获取 Claude Code 生成的脚本，再传给 plugin 执行；或者明确两套执行路径的职责

#### 2.5 `flutter_rust_bridge.yaml` 路径配置错误

`rust_input: rust/core/src/api.rs` 但文件不存在。`dart_output: lib/bridge` 目录也不存在，bridge 生成流程未完成。

#### 2.6 `Session.addRecord()` 状态固定为 completed

`lib/models/session.dart:54` — `addRecord` 总是创建 `TaskStatus.completed` 的记录，无法表示失败或运行中状态。

#### 2.7 Tab 切换未接通

`lib/app.dart:33` — `_currentTab` 初始化后从未被修改。侧边栏导航项（对话/任务/插件）点击回调 `widget.onTabSelected?.call(index)` 最终没有实际切换 `IndexedStack` 的面板。

---

### P2 — 质量改进

#### 2.8 Rust Clippy 警告（33+）

所有 17 个 Rust plugin 都缺少 `Default` trait 实现 (`new_without_default`)。其他警告包括 `if` 语句可简化、多余的 `return`、`map_or` 可简化等。

**修复**: `cargo clippy --fix --allow-dirty --workspace` 可自动修复大部分

#### 2.9 Flutter Analysis 警告（3）

`lib/core/task_orchestrator.dart:21-23` — `prefer_initializing_formals`: 字段赋值应使用 `this._pluginManager` 语法。

#### 2.10 SessionStore 中 Session 构造代码重复

`listBySoftware()`、`search()`、`load()` 三个方法中都有几乎相同的 `Session(...)` 构造逻辑，应抽取为 `_deserializeSession()`。

#### 2.11 缺失错误状态/空状态 UI

所有 UI 组件缺少 ErrorWidget/错误边界、网络断连提示、重试机制。`SoftwarePanel` 和 `TaskDashboard` 未区分「加载中」和「空数据」状态。

#### 2.12 TaskDashboard 筛选与数据流脱节

筛选逻辑已实现但 `_tasks` 列表的初始数据始终为空，且没有从外部添加任务的方法暴露给调用方。

#### 2.13 Blender Linux 路径 fallback 逻辑缺陷

`rust/plugins/blender/src/lib.rs:78` — `Some("blender".into())` 无条件返回，`Path::new("blender").exists()` 检查的是当前工作目录下的 `blender` 文件，而非 `$PATH` 中的可执行文件。

---

### P3 — 优化建议

#### 2.14 无国际化 (i18n)

代码中中英文字符串硬编码混合。UI 文案分散在各组件中，无统一管理。

#### 2.15 输入未做消毒处理

`CCRunner._buildPrompt()` 直接将用户输入嵌入 prompt 模板，没有转义或消毒。用户输入可能包含 prompt injection 内容。

#### 2.16 插件市场数据硬编码

`lib/ui/plugin_marketplace.dart` 和 `lib/ui/software_panel.dart` 中的软件列表为硬编码（8 个条目），与 Rust 侧 17 个 plugin 不同步。

#### 2.17 无 CI/CD 配置

项目缺少 GitHub Actions 或其他 CI 配置文件。

#### 2.18 无统一日志/遥测

虽然依赖了 `logging` 包，但只在一个文件中使用。

#### 2.19 调试文件残留

磁盘上有 `flutter_01.log`、`flutter_02.log`、`ruvector.db`、`.swarm/memory.db-*` 等调试残留文件。

#### 2.20 Rust 依赖优化

- `rust/core/Cargo.toml` — `tokio` 已声明但 core crate 没有异步代码
- 部分 plugin 的 tokio feature 可裁剪（如 figma 用 `full`）

---

## 三、Rust 测试覆盖

| Crate | 单元测试 | 集成测试 | Doc 测试 |
|-------|---------|---------|----------|
| ai_design_core | 0 | 0 | 0 |
| 17 个 plugin crate | 0 | 0 | 0 |

**总计: 0 个 Rust 测试**

## 四、Dart 测试覆盖

| 模块 | 测试数 | 覆盖评估 |
|------|--------|---------|
| ChatView | 4 | 良好 |
| Shell UI | 12 | 良好 |
| PluginManager | 7 | 良好 |
| ModelRouter | 5 | 良好 |
| SessionStore | 5 | 良好 |
| TaskOrchestrator | 5 | 良好 |
| CCProcessManager | 5 | 良好 |
| DesignPlugin SDK | 6 | 良好 |
| CCRunner | 3 | 仅 prompt |
| App Shell | 1 | 仅渲染 |
| PluginMarketplace | 1 | 仅渲染 |
| Session Model | - | 有文件 |
| **TaskDashboard** | **0** | 缺失 |
| **SoftwarePanel** | **0** | 缺失 |
| **SettingsView** | **0** | 缺失 |

**总计: 49 passed / 无失败**

---

## 五、安全审查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| 密钥泄露 | 通过 | `FIGMA_ACCESS_TOKEN` 从 env 读取 |
| 命令注入 | 警告 | `CCRunner._buildPrompt` 直接拼接用户输入 |
| SQL 注入 | 通过 | 使用 sqflite 参数化查询 |
| 输入校验 | 警告 | 无任务描述长度限制、无特殊字符过滤 |
| 环境变量泄露 | 警告 | `CCRunner.execute()` 传递所有 env vars |

---

## 六、修复优先级

| 优先级 | 问题 | 预估工时 |
|--------|------|---------|
| **P0** | 创建 api.rs + 生成 bridge 代码 | 2h |
| **P0** | 对接 ChatView → TaskOrchestrator | 1h |
| **P0** | 修复 Tab 切换逻辑 | 30min |
| **P1** | 修复 TaskOrchestrator 执行路径 | 30min |
| **P1** | 补充 Rust 核心插件测试 | 4h |
| **P1** | 修复 `Session.addRecord()` 状态逻辑 | 30min |
| **P2** | 修复所有 Clippy 警告 | 30min |
| **P2** | 修复 Flutter analyze 警告 | 15min |
| **P2** | 抽取 SessionStore 重复代码 | 30min |
| **P2** | 修复 Blender Linux fallback | 15min |
| **P3** | 添加 i18n 框架 | 3h |
| **P3** | 输入消毒 | 30min |
| **P3** | CI/CD 配置 | 1h |

---

## 七、总结

项目架构设计合理，分层清晰（Dart UI → Core → Rust Plugin SDK → Plugin impls）。Dart 端测试覆盖较好（49 用例全通过），但 Rust 端测试空白是最大短板。

**关键发现**:
- **3 个 P0 阻断问题**: bridge 未生成、ChatView mock、Tab 切换未接通
- **33+ 个 Rust Clippy 警告**: 可一键自动修复
- **Rust 端 0 测试覆盖**: 需优先补充
- **项目处于 MVP 架构完成阶段**: 核心骨架质量良好，下一阶段应聚焦 UI 交互完善和功能链路打通

**推荐修复路线**: P0 → 使应用端到端可运行 → P1 修复逻辑问题 + 补齐 Rust 测试 → P2 清理代码质量警告 → P3 基础设施优化
