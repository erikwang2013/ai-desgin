# Review Report 2026-08-07 v24 — Full Test & Deep Inspection

## 验证结果

| 检查 | 命令 | 结果 |
|------|------|------|
| 静态分析 | `flutter analyze` | ✅ No issues found (7.7s) |
| 全部测试 | `flutter test` | ✅ 99/99 passed（98 + 1 个新回归测试） |
| Rust 检查 | `cargo check` + `cargo clippy` | ✅ 通过，0 错误 0 警告 |
| 审查范围 | Rust 全工作区（40 crates 全部 `Command::output()`/`spawn()` 调用点）+ 任务仪表盘 UI + README 声明 | 见下方发现 |

## v23.1 回归确认

| v23.1 修复（13 项） | 回归验证 |
|------------|----------|
| failGenerated / finally-close / exitCode / 容错反序列化 / 模型路由 / 空闲驱逐 / 插件 init 容错 / settings 异步边界 | ✅ 代码复查 + 99/99 测试通过（含 7 个 v23.1 回归测试） |
| Rust ipc/freecad 超时 | ✅ 复查：`ipc.rs:19` 有 Drop-kill 兜底，`freecad/script.rs:65` 走 `wait_with_timeout` |

## 发现（按严重度）

### P2

1. **Rust 17 个插件执行脚本无超时**（17 个 `plugins/*/src/script.rs`）
   全部使用 `Command::output()`：子进程挂起（软件崩溃、GUI 等待弹窗）或 stdout 管道写满时永久阻塞调用线程。v23.1 只修了 freecad/ipc 两处，其余 17 个插件（blender、autocad、openscad、chitubox、lychee、sketch、revit、sketchup、solidworks、illustrator、rhino、photoshop、fusion360、cura、orcaslicer、prusaslicer、simplify3d）带同一缺陷。

2. **6 个插件 `get_current_state` 探测同样无超时**（cura/orcaslicer/prusaslicer/simplify3d/autocad 的 `get_current_state` + blender 的 `which` 回退）
   连接探测（`--version`/`--info`/`--help`/AutoCAD 状态查询）走独立的 `.output()` 调用，软件卡死时连接面板的探测同样永久阻塞。

### P3

3. **任务卡片显示软件 id 而非显示名**（`lib/app.dart:253`）
   提交任务后 `TaskItem(software: result.sessionId)` 显示的是插件 id（如 `blender`）而非显示名（`Blender`）；会话历史恢复路径（`task_dashboard.dart:62` 的 `s.softwareName`）同样显示 id。`BuiltInPlugin` 同时有 `id`（小写）与 `name`（首字母大写）两个字段。

4. **README 误导性声明**（`README.md:125`）
   `api.rs` 标注为「Flutter-Rust bridge API」，实际该文件是 Rust 侧插件查询 API（JSON 输出），整个 Rust 层独立运行、无 FFI 集成。标注与事实不符，误导后续维护者寻找不存在的桥接层。

## 修复记录（v24.1）

### 修复清单（4/4）

| # | 问题 | 严重度 | 修复 | 文件 |
|---|------|--------|------|------|
| 1 | 17 个插件执行无超时 | P2 | 抽取共享超时助手 `proc.rs`（`run_command`/`run_command_with_timeout`：线程 reader + `recv_timeout(120s)` + 超时 kill，与 Dart 侧 120s 一致），17 个 `script.rs` 全部改用 | `rust/core/src/proc.rs`（新增）、17 个 `plugins/*/src/script.rs` |
| 2 | 6 处连接探测无超时 | P2 | 同 helper 转换 | `plugins/{cura,orcaslicer,prusaslicer,simplify3d,autocad,blender}/src/lib.rs` |
| 3 | 卡片显示软件 id | P3 | `_onSubmit` 用 `_pluginManager.get(sw)?.name ?? sw` 解析显示名；`TaskDashboard` 新增可选 `resolveSoftwareName` 回调，历史恢复路径同样解析 | `lib/app.dart`、`lib/ui/task_dashboard.dart` |
| 4 | README 桥接声明误导 | P3 | 改为「Rust 侧插件查询 API（JSON 输出，独立运行）」 | `README.md:125` |

### 回归测试（+1）

- `task_dashboard_test.dart`：`restored history shows display name via resolveSoftwareName` — 真实 sqflite-ffi 内存库保存会话，验证恢复历史经 resolver 显示 `Blender` 而非 `blender`。
- 注：widget 测试内真实数据库 IO 需包在 `tester.runAsync` 中，否则 FakeAsync 区与 FFI IO 死锁（首个版本测试挂起，已修正）。

## 检查过但排除的问题

| 候选 | 结论 |
|------|------|
| Rust 其余 `spawn()` 调用 | ✅ 排除：全工作区仅 3 处 `spawn()`（ipc.rs / proc.rs / freecad），均有时超/kill 兜底 |
| 其余 `.output()` / `wait_with_output` | ✅ 排除：全工作区已清零 |
| `task_dashboard._cancelTask` 回调先于 setState | ✅ 保留：回调抛异常时 UI 不更新的风险极低，不引入额外容错 |
| API key 明文存 SharedPreferences | ✅ 已知限制（v23 记录），继续沿用，不引入新依赖 |

## 结论

整体健康：analyze / test / clippy 全绿，99/99 测试通过。本轮主题：**把 v23.1 的超时修复从 freecad 一处推广到整个 Rust 层**——23 处 `Command::output()`（17 个插件执行 + 6 处探测）全部统一到共享的 `proc.rs` 超时助手，Rust 侧不再有任何无超时的外部进程调用；顺带修复任务卡片软件名显示与 README 误导声明。Rust 转换后工作区 0 错误 0 警告，Dart 侧 99/99 通过。

## 技术说明

- `proc.rs` 的 `run_command` 返回 `(String, String, ExitStatus)` 三元组，替代 `Output`；调用方同步改为 `status.code()` 而非 `output.status.code()`。
- fusion360 因签名变更需显式 `use std::process::ExitStatus;`（cfg 分支共用同一类型标注）。
- 各插件 Linux 分支（无法运行对应软件的平台）保持原有错误返回语义不变，仅统一了进程调用路径。

## v24.2 补充：全量问题盘点 + 文档/图片同步

### 盘点结论

| 报告来源 | 问题 | 状态 |
|----------|------|------|
| v14 | 3 个测试文件不被裸 `flutter test` 发现 | ✅ 已解决（当前 99/99 全发现，17 个测试文件全部 `_test.dart` 命名） |
| v19 | 空闲会话无周期驱逐定时器 | ✅ v19.1 已修（`Timer.periodic(60s)` + 300s 超时） |
| v19 | freecad `exec(open(r"$scriptPath"))` 路径引号注入 | ✅ 已修（改用 `--runscript <path>` argv 传递，无源码内插） |
| v19/v20/v23 | API key 明文存 SharedPreferences | ⚠️ 环境约束（无 libsecret、无 Linux 构建目标、测试 MissingPluginException），维持文档化处理：README + security 图 + 本报告均已如实标注 |
| v20 | `key == null` 全量 kill 分支无调用方 | ✅ 接受（低风险，有意保留） |
| v21 | 取消后仍执行本地脚本 / 软件选项缓存陈旧 | ✅ v21.1 已修 |
| v22 | 卸载插件市场消失 / 启动不恢复 / cancel 无 UI | ✅ v22.1 已修 |
| v23 | 7 P2 + 6 P3（失败路径按失败处理） | ✅ v23.1 已修 |
| v24 | Rust 23 处无超时 / 卡片显示软件 id / README 桥接声明 | ✅ v24.1 已修 |
| 本会话意外 | 版本回归：`pubspec.yaml` 与 `rust/Cargo.toml` 从提交值 1.4.0 被降为 1.2.7（`git log -S` 确认 1.2.7 从未出现在任何提交中，属本会话误改） | ✅ 已恢复 1.4.0，Cargo.lock 重生成后与 HEAD 一致（0 diff） |

### 图片同步（本版本）

架构图此前与 README 一样声称存在 `flutter_rust_bridge FFI 调用`——与事实不符（Rust 层独立运行、无 FFI）。两张架构图已修正：

| 图片 | 修改 |
|------|------|
| `docs/diagrams/architecture-en.svg` | Rust 层副标题 → "Standalone crates (no FFI bridge)"；Core→Rust 连线去箭头改虚线，标签 → "Independent (no runtime calls)" |
| `docs/diagrams/architecture-zh.svg` | Rust 层副标题 → "独立 crate（无 FFI 桥接）"；连线改虚线，标签 → "独立运行（无运行时调用）" |

其余核对通过（无需修改）：security 图已如实标注明文密钥为已知限制；lifecycle 图「Timeout 300 s」与代码（`idleTimeoutSeconds = 300` + 60s 周期驱逐）一致；task-flow / features 图无桥接表述；l10n en/zh 60 键完全同步；lib/ 无 TODO/FIXME 残留。

### 验证（修复后）

| 检查 | 结果 |
|------|------|
| `flutter analyze` | ✅ No issues found |
| `flutter test` | ✅ 99/99 passed |
| `cargo check` + `cargo clippy` | ✅ 0 错误 0 警告 |
| SVG 合法性 | ✅ 两张编辑过的 SVG 均通过 XML 解析 |
