# AI Design Studio — 代码审查报告

**审查日期**: 2026-07-31  
**分支**: main  
**审查范围**: Dart/Flutter 前端 + Rust 插件后端  
**测试状态**: 49/49 通过 | Rust cargo check: 通过 | Flutter analyze: 15 info 级别提醒

---

## 总览

| 维度 | 评分 | 说明 |
|------|------|------|
| 测试 | B | 49 个 Dart 测试全部通过，但 Rust 侧无测试 |
| 代码质量 | B+ | 少量 lint 问题，部分功能为占位桩 |
| 安全性 | B | 无明显安全漏洞，但缺少输入校验 |
| 架构 | A- | 插件架构清晰，Dart/Rust 边界合理 |
| 功能完整性 | C+ | 核心架构完成，但 UI 交互多处未接通 |

---

## 一、静态分析问题 (15 条 info 级别)

```
lib/app.dart:32              '_currentTab' 应为 'final' (从未被修改)
lib/core/task_orchestrator.dart:21-23  构造函数应使用 initializing formal
test/core/cc_process_manager_test.dart:13,14,20,21,29,30,38,39,47,48  共12处 final 变量应为 const
test/core/session_store_test.dart:2    sqflite 导入可省略 (已由 sqflite_common_ffi 覆盖)
```

**建议**: 修复 `_currentTab` 时需一并添加缺失的 tab 切换逻辑（见下文），其余 lint 可一键修复。

---

## 二、功能缺陷

### 2.1 【严重】Tab 切换未接通

`lib/app.dart:32` — `_currentTab` 初始化后从未被修改。侧边栏的领域切换（`AppShell.onDomainChanged`）未连接到 `_MainShell` 的 tab 切换逻辑。点击侧边栏领域列表不会切换 `IndexedStack` 显示的内容面板。

### 2.2 【中等】TaskDashboard 筛选芯片无效

`lib/ui/task_dashboard.dart:94-100` — `_buildChip` 的 `onSelected` 是空回调 `(_) {}`，"全部/进行中/已完成" 筛选无实际效果。

### 2.3 【中等】多处 UI 占位桩未接通

| 位置 | 功能 | 状态 |
|------|------|------|
| `software_panel.dart:47` | "安装插件" 按钮 | 点击无响应 |
| `settings_view.dart:13` | 模型配置 | 无导航目标 |
| `settings_view.dart:24` | 代理设置 | 无导航目标 |
| `settings_view.dart:28` | 关于页面 | 无详情页 |
| `task_dashboard.dart:41` | `addTask()` | 方法已定义但从未被外部调用 |

### 2.4 【中等】`task_orchestrator.dart:56` — 脚本字段使用不当

将 task 描述字符串当作 `script` 存储。`TaskRecord.script` 应存储实际执行的脚本代码，此处应使用 `CCRunner` 生成的脚本，或在此阶段明确区分「任务描述」与「生成脚本」。

### 2.5 【低】`cc_runner.dart:151` — 未使用的参数

`_buildPrompt` 接受 `String? model` 参数但 prompt 模板中完全不使用它。model 仅在环境变量 `CLAUDE_DEFAULT_MODEL` 中设置。

---

## 三、Rust 侧问题

### 3.1 【低】`ipc.rs` — `send_script` 不读取 stdout

写入脚本到 stdin 后未读取 stdout/stderr，始终返回空字符串。调用者无法获取执行结果。

### 3.2 【低】`IsolatedProcess` 已导出但未被使用

`rust/core/src/lib.rs:3` 导出 `ipc` 模块，但全项目没有地方使用 `IsolatedProcess`。

### 3.3 【低】Blender Linux fallback 不安全

```rust
// rust/plugins/blender/src/lib.rs:78
Some("blender".into())  // 无条件返回，即使 blender 未安装
```

当 `/usr/bin/blender` 和 `/snap/bin/blender` 都不存在时，仍返回 `Some("blender")`，导致 `check_connection` 误报为 `Connected`（`Path::new("blender")` 只检查路径字符串格式，不检查文件存在性）。

### 3.4 【低】未使用的依赖

`rust/core/Cargo.toml` — `thiserror = "1"` 已声明但在 core crate 中完全未使用。

### 3.5 【低】tokio 全特性依赖

`rust/plugins/figma/Cargo.toml` — `tokio = { version = "1", features = ["full"] }` 启用了所有特性，实际只需 `rt-multi-thread` 和 `macros`。

---

## 四、架构与设计

### 4.1 优点

- Dart/Flutter 前端与 Rust 后端通过 `flutter_rust_bridge` 绑定，边界清晰
- 插件系统设计良好：`DesignPlugin` trait → 各软件独立 crate 实现
- Rust workspace 结构合理：`core` + 独立 `plugins/*` crate
- 模型路由 (ModelRouter) 支持按领域/复杂度匹配模型，可配置化
- Session/TaskRecord 模型设计完整，支持持久化

### 4.2 改进建议

| 建议 | 说明 |
|------|------|
| ChatView 消息持久化 | 消息仅存内存，重启丢失 |
| TaskOrchestrator 集成 CCRunner | `submitTask` 调用 `plugin.execute()` 而非通过 Claude Code CLI 生成脚本 |
| 添加错误边界 | UI 层缺少全局 error widget，Rust panic 可能导致 FFI 崩溃 |
| Session 数量管理 | `TaskOrchestrator._sessions` 无上限限制 |

---

## 五、测试覆盖分析

### 已有测试 (49 个，全部通过)

| 模块 | 测试数 | 覆盖内容 |
|------|--------|----------|
| `chat_view_test` | 4 | 输入框、发送按钮、消息添加 |
| `shell_test` | 12 | 侧边栏、领域切换 |
| `plugin_marketplace_test` | 1 | 已安装/可安装列表 |
| `cc_process_manager_test` | 5 | 会话创建、限制、请求构建 |
| `task_orchestrator_test` | 5 | 任务提交、失败、取消 |
| `cc_runner_test` | 3 | Prompt 构建、JSON 解析 |
| `session_store_test` | 5 | CRUD 操作 |
| `model_router_test` | 5 | 路由匹配、fallback、覆盖 |
| `design_plugin_test` | 6 | 元数据、执行、状态 |
| `widget_test` | 1 | App 默认渲染 |

### 测试缺口

- **Rust 侧**: 0 个测试（core + 4 个 plugin crate 均无测试）
- **UI 层未覆盖**: `TaskDashboard`、`SoftwarePanel`、`SettingsView`、`PluginMarketplace`（仅 1 个测试）
- **集成测试**: 无端到端测试
- **边界测试**: 大量消息时的性能测试、并发任务提交测试

---

## 六、安全审查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| 密钥泄露 | 通过 | `FIGMA_ACCESS_TOKEN` 从 env 读取 |
| 命令注入 | 警告 | `CCRunner._buildPrompt` 直接拼接用户输入到 prompt |
| SQL 注入 | 通过 | 使用 sqflite 参数化查询 |
| 输入校验 | 警告 | 无任务描述长度限制、无特殊字符过滤 |
| 依赖安全 | 通过 | Rust 依赖版本较新 |

---

## 七、优化建议汇总

### 立即修复 (P0)

1. 接通 tab 切换逻辑 — `app.dart:_currentTab` 可修改变量 + 侧边栏回调
2. 修复 lint 警告 — `dart fix --apply`

### 短期优化 (P1)

3. TaskDashboard 筛选芯片接通筛选逻辑
4. 补全 UI 占位桩（安装插件、设置子页面路由）
5. `task_orchestrator.dart` 中 `script: task` → 使用实际生成的脚本
6. Blender Linux fallback 修复 — 路径检查使用 `exists()`

### 中期优化 (P2)

7. 为 Rust core 和 plugin crate 添加单元测试
8. ChatView 消息数量上限 + 持久化
9. 修复或移除 `ipc.rs` 中未完成的 `send_script`
10. 移除 `thiserror` 依赖或开始使用
11. figma plugin tokio 改为 `features = ["rt-multi-thread"]`

### 长期优化 (P3)

12. 添加端到端集成测试
13. 为 TaskOrchestrator 添加重试和超时机制
14. 考虑引入状态管理库（`riverpod`/`flutter_bloc`）
15. 添加 CI/CD pipeline

---

## 八、项目文件清理

| 文件 | 原因 |
|------|------|
| `flutter_01.log` | 调试日志残留 |
| `flutter_02.log` | 调试日志残留 |
| `ruvector.db` | 向量数据库残留文件 |
| `.swarm/memory.db-wal` | 数据库 WAL 残留 |
| `.swarm/memory.db-shm` | 数据库 SHM 残留 |
| `build/` | 构建输出 |

（以上文件均已被 `.gitignore` 忽略，但磁盘上仍有残留）

---

## 总结

项目整体架构设计良好，Dart/Rust 分层清晰，插件系统可扩展性强。49 个测试全部通过，无编译错误。主要问题集中在：

1. **UI 交互未接通** — tab 切换、筛选器、多处按钮为占位桩
2. **部分功能逻辑不完整** — 脚本生成与实际执行链路未打通
3. **Rust 侧缺少测试** — 0 个 Rust 单元测试
4. **少量代码质量瑕疵** — 15 条 lint 警告、未使用的依赖和模块

项目处于 **MVP 架构完成阶段**，核心骨架质量良好，下一阶段应聚焦 UI 交互完善和功能链路打通。
