# 审查报告 — 2026-08-06 (v16) — 修复轮次

## 执行摘要

针对生态完整性深度审查发现的 10 类问题全部修复。65/65 测试通过，`dart analyze` 零问题，`cargo check` / `cargo clippy` 零警告。版本统一为 1.3.0。

## 测试结果

```
flutter test          → 65 passed, 0 failed
dart analyze lib test → No issues found
cargo check --workspace → Finished (0 warnings)
cargo clippy --workspace → Finished (0 warnings)
```

## 已修复问题（10 类）

| # | 问题 | 修复 |
|---|------|------|
| 1 | `config/model-routing.yaml` 存在但从未加载 | 注册为 asset，启动时 `rootBundle` 加载 + inline fallback |
| 2 | 12 个 Rust-only 插件未注册到 Dart | 全部注册进 `builtin_plugins`，50 → 62 |
| 3 | i18n 漂移（50/59/62 数字不一致） | 12 个 ARB 文件同步 62 款，新增 9 个 key，`gen-l10n` 重新生成 |
| 4 | 语言切换无 UI | 设置页语言选择 SimpleDialog + `LocaleProvider` 持久化 |
| 5 | 设置页模型/代理为 Coming Soon 占位 | 完整功能页：模型配置（api_endpoint/api_key/default_model）+ 代理设置（proxyEnvironment 注入 CLI） |
| 6 | 无真实执行层 | 新增 `LocalScriptExecutor`：9 个 CLI 插件真实执行（`--version` 探测 + 60s 缓存），其余诚实 fallback"脚本已生成，请手动执行" |
| 7 | 市场卸载仅内存、任务历史不恢复 | 卸载状态 `shared_preferences` 持久化；`SessionStore.listRecent` + 启动时恢复历史 |
| 8 | Rust Figma 插件 DUMMY_KEY 硬编码 | 依赖无关的 URL key 提取（`figma.com/design/{fileKey}`，22 位），缺失时报中文错误 |
| 9 | README/版本漂移（50 插件、49 测试、过期架构图） | 全量修订 + 仓库卫生（删残留文件），版本统一 1.3.0 |
| 10 | 测试覆盖不足 | 新增 5 个测试（LocalScriptExecutor ×2、listRecent、setDefaultModel、市场持久化），60 → 65 |

## 执行层（修复 #6）

- **CLI 能力插件**（blender / freecad / openscad / cura / prusaslicer / orcaslicer / simplify3d / chitubox / lychee）：`Process.run` 真实执行，参数按插件定制，超时 5s。
- **其余插件**：生成脚本 + 明确提示"安装并启动软件后手动执行"，不再假装执行成功。
- 连接状态：启动时探测 CLI 可用性，软件面板展示真实连接状态。

## 生态配置

### 62 插件领域分布

| 领域 | 数量 |
|------|------|
| 工业设计 (industrial) | 22 |
| 3D 设计 (threeD) | 15 |
| 广告设计 (ad) | 14 |
| Web 设计 (web) | 5 |
| 装修设计 (interior) | 4 |
| 建筑设计 (arch) | 2 |

### 版本: 1.3.0 三处一致

`pubspec.yaml` = `version.dart` = `Cargo.toml` = 1.3.0

## 结论

**代码健康度: A** — 10 类问题全部修复，65 测试全绿，analyze/clippy 零告警，62 插件覆盖 6 领域，12 语言 i18n 全链路。
