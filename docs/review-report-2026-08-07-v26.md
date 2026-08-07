# Review Report 2026-08-07 v26 — Rust 内核真正集成（FFI + 注册表权威化）

## 验证结果

| 检查 | 命令 | 结果 |
|------|------|------|
| 静态分析 | `flutter analyze` | ✅ No issues found |
| 全部测试 | `flutter test` | ✅ 106/106 passed（102 原有 + 3 rust_integration + 1 ffi_smoke） |
| Rust 单测 | `cargo test -p ai_design_core` | ✅ 4/4 passed（注册表完整性断言） |
| Rust 检查 | `cargo clippy --workspace` | ✅ 0 错误 0 警告 |
| 构建链 | `bash scripts/build.sh` | ✅ 产出 release bundle，`libai_design_core.so` 与 libapp.so 同目录 |
| 两态冒烟 | FFI 测试 + 回退测试 | ✅ 有 .so → 真实加载 Rust 注册表（62 条）；无 .so → Dart 回退（62 条） |
| 图表 | 10 张 SVG | ✅ xmllint 全部合法，架构图已更新，其余内容与现状一致 |

## 本轮主题

审查发现 Rust workspace（core + 39 插件 crate，全部编译通过）从未被 App 使用：
flutter_rust_bridge.yaml 配置了但绑定从未生成、pubspec 无 rust 依赖、build.sh 编译 cargo 但从不复制产物、
release.sh 完全不编译 Rust、`api.rs` 是硬编码 8 个插件的死代码（与 Dart 侧 62 个插件冲突）。
用户决策：**真正集成**，Rust 成为运行时插件注册表权威源，FFI 失败回退 Dart 常量（双保险）。

## 修复记录（v26.1）

| # | 问题 | 严重度 | 修复 | 文件 |
|---|------|--------|------|------|
| 1 | Rust 层从未被 App 使用（死代码 + 第三套冲突数据） | P1 | `api.rs` 重写为 FFI 边界（3 个 String 函数）；新增 `registry.rs` 注册表唯一数据源（62 条，从 builtin_plugins.dart 转录，含 icon/description/capabilities）；`Cargo.toml` 加 `[lib] crate-type = ["cdylib","rlib"]` | `rust/core/src/api.rs`、`rust/core/src/registry.rs`（新）、`rust/core/Cargo.toml`、`rust/core/src/lib.rs` |
| 2 | FRB 绑定从未生成 | P1 | 安装并锁定 flutter_rust_bridge 2.12.0，codegen 生成 `lib/bridge/`（3 函数 String 入出参，零自定义类型） | `pubspec.yaml`、`flutter_rust_bridge.yaml`、`lib/bridge/`（生成物）、`rust/core/src/frb_generated.rs`（生成物） |
| 3 | PluginManager 只认 Dart 常量，无 Rust 权威通道 | P1 | 新增 `static Future<PluginManager> create()`：FFI 拉取注册表 → 成功 `rustConnected=true`；异常吞掉回退 Dart 常量。现有同步 API 不动（62 测试零影响） | `lib/core/plugin_manager.dart` |
| 4 | `BuiltInPlugin` 无法解析 Rust JSON | P2 | 新增 `factory BuiltInPlugin.fromRustJson()`：category 字符串 → DesignCategory switch、capabilities 解析、缺失字段空列表兜底 | `lib/plugin_sdk/design_plugin.dart` |
| 5 | App 启动仍注册 Dart 常量（注册循环与 uninstalledIds 过滤） | P2 | `_initOrchestrator` 改为 `await PluginManager.create()`，注册循环改遍历 `getAll()`（过滤逻辑不变，两路注册后都过滤）；`late final` → `late` + 同步占位，消除 async 前 build 的 LateInitializationError | `lib/app.dart` |
| 6 | 用户无法感知 Rust 连接状态 | P3 | 软件面板标题栏下新增状态行：绿色「Rust 内核已连接 · 注册表来自 Rust」/ 灰色「Rust 内核未连接 · 使用 Dart 内置注册表」 | `lib/ui/software_panel.dart` |
| 7 | 构建链不产出动态库 | P2 | build.sh 加 cargo build + 复制 .so 进 bundle；build_windows.bat 加 DLL 复制；release.sh 加 Rust 编译 + Linux bundle 打包，macOS 分支 TODO 文档化 | `scripts/build.sh`、`scripts/build_windows.bat`、`scripts/release.sh` |
| 8 | 项目缺 Linux 平台目录（只有 macos/windows） | P2 | `flutter create --platforms=linux .` 生成 `linux/`，与 build.sh 的 Linux 分支对齐 | `linux/`（新） |
| 9 | 进程管道单线程读 stdout+stderr：64KB 满管死锁 | P2 | stdout/stderr 各起独立读取线程并发排空；超时路径 kill + `child.wait()` 收尸（防僵尸）+ join 两个读取线程；`err_handle` 克隆 tx 修复 send 失败导致线程 panic 的隐患 | `rust/core/src/proc.rs`、`rust/core/src/ipc.rs` |
| 10 | IPC 子进程 stderr 被静默丢弃 | P3 | stderr 非空时返回 `Err("Process stderr: ...")`，错误不再被吞 | `rust/core/src/ipc.rs` |
| 11 | 聊天消息超限裁剪只在发送路径执行 | P3 | 抽取 `_trimMessages()`，响应/错误回调也裁剪（长回复后内存不再无限增长） | `lib/ui/chat_view.dart` |
| 12 | 代理 scheme（https://）输入被强制 http，且重启后 scheme 丢失 | P3 | 保存时识别 scheme 并持久化 `proxy_scheme`，重建代理 URL 用保存的 scheme | `lib/ui/settings_view.dart` |

### 新增测试（+4）

- `rust_integration_test.dart`（3）：无库环境 `create()` 不抛异常、`rustConnected==false`、注册数 62 且 6 分类齐全、figma capabilities 含「画布」。
- `ffi_smoke_test.dart`（1）：有 `.so` 时 `ExternalLibrary.open` + `RustLib.init` 真实加载，断言 62 条唯一 id、figma category/capabilities、rustVersion；产物缺失时 `markTestSkipped`（CI/未构建环境不误报）。

## 检查过但排除的问题

| 候选 | 结论 |
|------|------|
| types.rs 与 registry.rs 的 PluginMeta 重复（codegen 警告） | ✅ 排除：API 签名不使用该类型，警告无害；traits.rs 仍在用 types.rs 版本，删除会破坏插件 crate |
| 删除 builtin_plugins.dart（Rust 权威后 Dart 侧成冗余） | ✅ 排除：保留作 FFI 失败回退，双保险设计，永不删除 |
| 为 FFI 生成自定义类型绑定（PluginMeta 结构体直传） | ✅ 排除：String 入出参最小面，兼容性最稳，重生成成本最低 |
| icon/description 走旁路表（app.dart softwareIcons / marketplace softwareDescriptions） | ✅ 排除：本轮不动 UI 消费路径，注册表权威化只影响 id/name/category/capabilities |
| macOS 真机验证 | ✅ 文档化 TODO：本机无 mac，脚本按 FRB 官方实践编写（dylib 复制 + codesign），标注真机验证 TODO |
| 历史报告 v14-v25 遗留 | ✅ 全部核对：v14 的 test-discovery 问题已在 106 测试全绿时自然解决；lib/ 无 TODO/FIXME 残留 |

## 结论

Rust 层从「从未被使用」变为运行时注册表权威源：FFI 管道（String 入出参）已打通并锁定版本，
62 条插件元数据以 Rust 为准、Dart 常量兜底，两态（有/无 .so）均有自动化测试给出决定性证据。
构建链（build.sh / build_windows.bat / release.sh）补齐动态库产物，Linux 平台目录已生成。
全部 106 Dart 测试 + 4 Rust 单测 + clippy 0 警告。`builtin_plugins.dart` 永不删除，删除 .so 即恢复旧行为，回滚单 commit。

## 技术说明

- FRB 2.12.0 锁版本（`=2.12.0`）；codegen 后 lib.rs 注入 `mod frb_generated;`（生成物 rust/core/src/frb_generated.rs，随源码提交）。
- FFI 冒烟测试用 `ExternalLibrary.open(path)` 显式 dlopen release bundle 的 .so，避免 flutter run 重建 bundle 覆盖手动拷贝产物的问题。
- `create()` 的 catch 吞掉 FFI/解析异常并 `dev.log` 留痕；回退路径与 FFI 路径都经过 uninstalledIds 过滤，行为一致。
- 代理 scheme 持久化新增 1 个 SharedPreferences 键（`proxy_scheme`），旧配置（无 scheme 键）默认 http，向后兼容。
