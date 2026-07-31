# AI Design Studio — 审查报告 v2

**日期**: 2026-08-01（第二版）
**分支**: main
**当前状态**: Dart 0 issues | 49 tests passed | Rust cargo check 0 warnings

---

## 概览

| 维度 | 状态 |
|------|------|
| Dart 静态分析 | 0 issues |
| Flutter 测试 | 49/49 通过 |
| Rust 编译 | clean (0 warnings) |
| **关键问题** | **4** |
| **警告** | **6** |
| **建议** | **4** |

---

## 关键问题

### 1. PluginManager 从未注册插件 — 应用端到端不可用

`plugin_manager.dart:7` 定义了 `register()` 方法，但在 `app.dart` 的 `_initOrchestrator()` 中创建的 `PluginManager()` 完全为空——没有任何地方调用 `register()`。因此 `TaskOrchestrator.submitTask()` 在任何软件上都会立即返回 `"Software not found"`，应用核心流程完全不可用。

**修复方向**: `_initOrchestrator` 中注册所有可用插件的实例。

### 2. 模型→脚本流水线为空操作 — `task_orchestrator.dart:53-56`

```dart
final request = _ccManager.buildRequest(...);
_ccManager.serializeRequest(request);  // 序列化后丢弃
final result = await plugin.execute(task);  // 执行原始 task 文本，非生成脚本
```

`buildRequest()` + `serializeRequest()` 只构建 JSON-RPC 请求并转为字符串，从未调用 `executeWithClaude()` 真正发送给 Claude CLI。随后 `plugin.execute(task)` 将用户的原始自然语言任务文本直接作为脚本执行。用户输入「设计一个按钮」会被当作 Figma Plugin API 代码执行，必然失败。

**修复方向**: 调用 `executeWithClaude()` 获取模型生成的脚本，再将脚本传给 `plugin.execute()`。

### 3. 并发限制存在竞态条件 — `task_orchestrator.dart:38`

`activeTaskCount` 只统计 `status == running` 的记录，而 `submitTask` 在异步执行前先检查数量。两个并发的 `submitTask` 调用可以同时通过检查，导致实际并发超出 `maxConcurrent=3` 的限制。`cancelTask` 也无法中止正在执行的 `plugin.execute()`。

**修复方向**: 使用计数器（`_activeCount`）在异步操作前递增、完成后递减，使用 `Completer` 支持取消。

### 4. Meshy API 关键词路由错误 — `meshy/api.rs:53-57`

```rust
if script_lower.contains("text") {  // "texture" 也包含 "text"！
    text_to_3d(...)
} else if script_lower.contains("texture") {  // 永远不会到达
    generate_texture(...)
}
```

`"texture"` 包含子串 `"text"`，纹理生成请求被错误路由到 `text_to_3d`。此外 `"image"` 也匹配 `"optimize"` 中的——不，等等。让我重新确认：`"texture".contains("text") = true`，所以纹理请求确实会被 text_to_3d 拦截。需将 `texture` 检查放在 `text` 之前。

---

## 警告

### 5. 枚举反序列化缺少容错 — `session_store.dart:91,126,163`

```dart
DesignCategory.values.firstWhere((d) => d.name == row['domain'])
TaskStatus.values.firstWhere((s) => s.name == row['status'])
```

如果数据库中存储了无效的枚举值（如旧版本数据、手动修改），`firstWhere` 无 `orElse` 会抛出 `StateError` 导致查询崩溃。`model_router.dart:28` 的 `loadYaml` 同样缺少 try-catch。

### 6. cc_runner 无超时限制 — `cc_runner.dart:89`

```dart
final results = await Future.wait([
  process.stdout.transform(utf8.decoder).join(),
  process.stderr.transform(utf8.decoder).join(),
]);
```

没有 `.timeout()`，如果 Claude CLI 挂死，此 Future 永久阻塞，占用一个隔离线程。

### 7. Rust API id 不匹配 — `core/api.rs`

`list_plugins()` 返回 `"com.aidesign.figma"` 格式的 ID，但 `get_plugin_capabilities()` 用 `"figma"` / `"blender"` / `"autocad"` 裸名匹配。新增的 illustrator/sketch/revit/sketchup 在 `get_plugin_capabilities` 中的 `_` 分支返回 `{}`——即插件列表宣称存在，但查询能力时返回空对象。

### 8. SessionStore 从未使用 — 持久化层是死代码

`session_store.dart` 定义了完整的 SQLite 持久化方案，但 `app.dart` 中从未实例化 `SessionStore`。所有 orchestrator 的 session 和 task 只存在于内存 `Map` 中，应用重启后全部丢失。`_connectionStatus` 也未填充，SoftwarePanel 始终显示「检测中...」。

### 9. 路由优先级导致规则被遮蔽 — `model_router.dart`

```yaml
- domains: [industrial, threeD, arch, interior]
  model: claude-opus-4-7          # 域名路由
- complexity: simple
  model: claude-haiku-4-5         # 简单路由
```

域名路由匹配所有复杂度的 industrial/threeD/arch/interior 任务，排在 `simple` 路由之前。在工业设计领域输入「导出 STL」（被 `_inferComplexity` 识别为 simple）仍然消耗 Opus 资源。

### 10. 插件初始化行为不一致

| 插件 | 非目标平台行为 |
|------|---------------|
| Sketch | `initialize()` 返回 `Err("Sketch requires macOS.")` |
| Illustrator | `initialize()` 返回 `Ok(())` |
| SketchUp | `initialize()` 返回 `Ok(())` |

Sketch 返回错误会阻止 orchestrator 继续，而 Illustrator/SketchUp 静默通过。策略应统一。

---

## 建议

### 11. 版本号不一致

| 位置 | 版本 |
|------|------|
| `pubspec.yaml` | `1.0.0+1` |
| `settings_view.dart` | `v0.1.0` |
| `Cargo.toml` | `1.0.5` |
| `api.rs` (新插件) | `1.0.4` |
| `plugin_marketplace.dart` | `1.0.0` |

多处版本号不统一，`settings_view` 的 `v0.1.0` 明显过时。

### 12. 未使用代码

- `chat_view.dart:26` — `initState` 重写为空方法体
- `software_panel.dart:42` — `_toggleInstall` 声明为 `async` 但无 `await`
- `cc_runner.dart` — `buildPromptForTest` 仅在测试中使用，可标记 `@visibleForTesting`

### 13. 性能问题

- `session_store.dart:53` — `save()` 对每个 history 记录做一次 `SELECT` + `INSERT`（N+1 查询）
- `blender/src/lib.rs` 的 `get_current_state()` 每次调用启动完整 Blender 进程

### 14. UX 改进

- 切换到新消息时 ChatView 不自动滚动到底部
- 切换设计领域时 `ValueKey('chat_${_currentDomain.name}')` 会丢弃当前聊天历史

---

## 变更影响矩阵

| 文件 | 状态 | 问题 |
|------|------|------|
| `app.dart` | 🔴 | 未注册插件、未使用 SessionStore、未填充连接状态 |
| `task_orchestrator.dart` | 🔴 | 模型流水线断链、并发竞态 |
| `meshy/api.rs` | 🔴 | 关键词路由顺序错误 |
| `core/api.rs` | 🟡 | ID 格式不匹配 |
| `session_store.dart` | 🟡 | 枚举反序列化无容错、N+1 查询 |
| `cc_runner.dart` | 🟡 | 无超时 |
| `model_router.dart` | 🟡 | 路由优先级遮蔽 |

---

## 量化总结

- **代码规模**: Dart 1869 行 + Rust 20+ 插件
- **测试**: 49 个全通过（但未覆盖关键流程的实际执行路径）
- **关键问题**: 4 个（应用可用性 + 流水线完整性）
- **警告**: 6 个
- **建议**: 4 个
- **v1 修复遗留**: 上一轮的 21 项修复全部保持有效
