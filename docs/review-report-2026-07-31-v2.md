# AI Design Studio — 代码审查报告 v2

**日期**: 2026-07-31  
**审查范围**: 全部代码库（Flutter + Rust）  
**版本**: 1.0.8  

---

## 执行摘要

Flutter 静态分析和 Rust cargo check 均无错误。Flutter 测试全部通过。项目整体结构清晰，插件化架构设计合理。发现 **1 个潜在运行时崩溃问题**、若干代码卫生问题和架构建议。

| 类别 | 数量 |
|------|------|
| 🔴 高风险 | 1 |
| 🟡 中风险 | 6 |
| 🟢 低风险/优化建议 | 8 |

---

## 🔴 高风险

### 1. `_deserializeSessionRows` 缺少 `orElse` — 可能崩溃

**文件**: `lib/core/session_store.dart:131`

```dart
domain: DesignCategory.values.firstWhere((d) => d.name == r['domain']),
```

`listBySoftware()` 和 `search()` 方法调用 `_deserializeSessionRows()`，该方法对 DB 中的 domain 字段使用 `firstWhere` 但无 `orElse` 兜底。如果数据库中存储了已删除或损坏的 domain 值，会直接抛出 `StateError` 导致应用崩溃。

对比同文件 line 97 的 `load()` 方法则正确使用了 `orElse: () => DesignCategory.web`。

**修复**: 为 `_deserializeSessionRows` 第 131 行添加 `orElse: () => DesignCategory.web`。

---

## 🟡 中风险

### 2. 三处独立维护的插件列表 — 同步风险

三个文件各自硬编码 27 个软件的列表，数据结构不同但内容高度重复：

| 文件 | 类型 | 用途 |
|------|------|------|
| `lib/app.dart` | `BuiltInPlugin` | 插件注册与执行 |
| `lib/ui/software_panel.dart` | `SoftwareInfo` | 已安装插件 UI |
| `lib/ui/plugin_marketplace.dart` | `PluginInfo` | 插件市场 UI |

新增一个软件需要同时修改三处，已存在不一致风险。建议抽取为单一数据源（如 JSON 配置文件或共享常量），各处从 `PluginManager` 或统一注册表读取。

### 3. `_inferComplexity` 过度匹配 'creative'

**文件**: `lib/core/model_router.dart:92`

```dart
final creativeKeywords = ['设计', '创意', ...];
```

`'设计'` 关键字几乎会匹配所有以中文描述的设计任务，导致大部分请求被路由到 `claude-opus-4-7`（成本最高的模型）。建议从 creative 关键词中移除 '设计'，或将其归入 moderate。

### 4. Rust 插件与 Flutter 包装器数量不对等

Rust 插件目录有 **39** 个插件，但 Flutter 端 `_builtInPlugins` 只有 **27** 个。以下 12 个 Rust 插件缺少 Flutter 包装器：

`chitubox, cura, freecad, lychee, meshy, openscad, orcaslicer, prusaslicer, rhino, simplify3d, solidworks, tinkercad`

这些在 `Cargo.toml` workspace members 中注册了，编译无问题，但对 Flutter 用户不可见。

### 5. CCRunner prompt 未覆盖新增软件

**文件**: `lib/core/cc_runner.dart:182-186`

Claude Code 调用 prompt 只列出了 Figma/Blender/AutoCAD/Photoshop 的脚本语言指导，未包含新增的 Maya (Python/MEL)、3ds Max (MaxScript/Python)、Cinema 4D (Python)、InDesign (JavaScript) 等。尽管这些软件使用已有的脚本语言类型，但缺少针对性的 API 提示会降低生成脚本质量。

### 6. 数据库无迁移策略

**文件**: `lib/app.dart:86-89`

```dart
final db = await openDatabase(
  '${dir.path}/sessions.db',
  version: 1,
  onCreate: SessionStore.onCreate,
);
```

`openDatabase` 调用没有 `onUpgrade` 回调。未来修改 schema 时，已安装用户将遇到崩溃而非平滑迁移。

### 7. ChatView 的 send button 每次按键重建

**文件**: `lib/ui/chat_view.dart:139-150`

`ListenableBuilder` 监听 `TextEditingController`，每个字符输入都会触发整个 button widget 重建。虽然开销不大，但可以使用 `ValueListenableBuilder` + 对 text 做 debounce 来优化。

---

## 🟢 低风险 / 优化建议

### 8. chat_view.dart dispose 时序问题

`_scrollToBottom()` 使用 `addPostFrameCallback` 但不检查 `_scrollController` 是否已 disposed。如果在回调执行前 widget 被销毁，会触发断言失败（debug 模式）。

### 9. 测试覆盖率不足

当前仅 3 个 widget 测试，覆盖 ChatView 渲染和 PluginMarketplace 基本操作。核心模块（TaskOrchestrator、ModelRouter、SessionStore、CCProcessManager）均无单元测试。建议至少为 SessionStore 的 CRUD 操作和 ModelRouter 的 route 逻辑添加测试。

### 10. 非标准文件扩展名

- `buildplanner`: `fileFormats: ['stl','layout','gcode']` — `'layout'` 非通用扩展名
- `waxjetprint`: `fileFormats: ['stl','wax','gcode']` — `'wax'` 非通用扩展名

建议使用行业标准扩展名，或在文档中说明这些自定义格式。

### 11. 模型路由配置硬编码

**文件**: `lib/app.dart:67-77`

模型路由的 YAML 配置直接以字符串形式写在 `_initOrchestrator()` 中。建议移到外部配置文件（assets 或 config 目录），便于用户自定义。

### 12. `plugin_marketplace.dart` 测试断言不稳定

```dart
expect(find.text('已安装 (27)'), findsOneWidget);
```

每次新增软件都需要手动更新测试。建议改为 `findsOneWidget` 配合正则匹配或动态获取已安装数量。

### 13. 关于对话框中的版本号前缀重复

**文件**: `lib/ui/settings_view.dart:35, 58`

关于弹窗中版本显示为 `v$appVersion`，其中 `appVersion` 值为 `'1.0.8'`，所以实际显示为 `v1.0.8`（一个 `v`），确认无问题。但若将来 `appVersion` 包含 `v` 前缀则会出现 `vv` 重复。建议统一版本号格式。

### 14. SessionStore search 方法使用子查询可优化

**文件**: `lib/core/session_store.dart:120-124`

```dart
SELECT DISTINCT s.* FROM sessions s
INNER JOIN task_records t ON t.session_id = s.id
WHERE t.task LIKE ? ESCAPE '\\'
```

对大批量数据，`DISTINCT` + `INNER JOIN` 可能较慢。考虑添加分页或对 `sessions` 表补充 `fts` 虚拟表。

### 15. 缺少加载状态指示器

`ChatView` 在等待 AI 响应时仅在发送按钮处显示 loading spinner。如果网络较慢或模型响应时间较长，用户缺乏明确的进度反馈。建议在对话区域显示 typing indicator。

---

## 验证结果

| 检查项 | 结果 |
|--------|------|
| `flutter analyze` | ✅ 无问题 |
| `flutter test` | ✅ 2 passed |
| `cargo check` | ✅ 编译通过 |
| `cargo test` | ✅ 通过（含 39 个插件） |
| Rust 插件数量 | 39 个 |
| Flutter BuiltInPlugin 数量 | 27 个 |
| Dart 代码总行数 | ~1904 行 |

---

## 优先级建议

1. **立即修复**: 问题 #1（崩溃风险）
2. **本次迭代**: 问题 #2（统一插件列表）、#5（扩展 prompt）、#13（版本号前缀）
3. **下个迭代**: 问题 #3（路由优化）、#6（数据库迁移）、#9（测试覆盖率）
4. **持续改进**: #4（补齐 Rust 插件包装器）、#10-12、#14-15
