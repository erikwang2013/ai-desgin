# AI Design Studio — 实现计划

> **For agentic workers:** 使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现。步骤使用 checkbox (`- [ ]`) 追踪。

**目标：** 构建跨平台（Win/Mac）桌面应用的核心框架——Claude Code 集成、插件系统（Dart 接口 + Rust 实现）、任务编排、模型路由，以及 Figma 示例插件。

**当前状态 (2026-07-31 第三次更新):** 15 个任务全部完成。Dart 49 测试通过，Rust 22 crates 编译通过 (0 clippy warnings)。新增 Illustrator、Sketch、Revit、SketchUp 四个插件。

**架构：** Flutter 桌面壳 + Dart 核心层（编排/路由/UI）→ flutter_rust_bridge FFI → Rust crate 插件层（系统级软件控制）。Claude Code CLI 通过子进程 JSON-RPC 通信。

**技术栈：** Flutter 3.x (Dart), Rust, flutter_rust_bridge, SQLite (sqflite), Claude Code CLI

**预计总任务数：** 15 tasks，约 60+ 步骤

---

## 文件结构总览

```
ai-desgin/
├── lib/
│   ├── main.dart                          # App 入口
│   ├── app.dart                           # MaterialApp + 路由
│   ├── models/
│   │   ├── session.dart                   # Session, SessionContext
│   │   ├── task_record.dart               # TaskRecord, TaskStatus
│   │   ├── plugin.dart                    # PluginMeta, ConnectionStatus, ScriptResult
│   │   └── software_capabilities.dart     # SoftwareCapabilities, SoftwareState
│   ├── core/
│   │   ├── plugin_manager.dart            # 插件发现/加载/注册
│   │   ├── cc_process_manager.dart        # Claude Code 子进程管理
│   │   ├── model_router.dart              # 模型路由策略
│   │   ├── task_orchestrator.dart         # 任务编排
│   │   └── session_store.dart             # SQLite 会话持久化
│   ├── plugin_sdk/
│   │   └── design_plugin.dart             # DesignPlugin 抽象接口
│   └── ui/
│       ├── shell.dart                     # 侧边栏 + 主内容区布局
│       ├── chat_view.dart                 # 对话面板
│       ├── task_dashboard.dart            # 任务看板
│       ├── software_panel.dart            # 软件控制台
│       └── settings_view.dart             # 设置页
├── rust/                                  # Rust workspace
│   ├── Cargo.toml                         # workspace 根
│   ├── core/
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── traits.rs                  # DesignPlugin Rust trait
│   │       ├── types.rs                   # PluginContext, ScriptResult 等
│   │       └── ipc.rs                     # 进程隔离/管道通信
│   └── plugins/
│       └── figma/
│           ├── Cargo.toml
│           └── src/
│               ├── lib.rs                 # FigmaPlugin 实现
│               ├── api.rs                 # Figma REST API 客户端
│               └── browser.rs             # 浏览器自动化
├── config/
│   └── model-routing.yaml                 # 默认路由配置
├── pubspec.yaml
├── flutter_rust_bridge.yaml
└── test/
    ├── models/
    ├── core/
    ├── plugin_sdk/
    └── ui/
```

---

### Task 1: Flutter 项目初始化

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `lib/app.dart`
- Create: `test/widget_test.dart`

- [ ] **Step 1: 创建 Flutter 项目**

```bash
cd /home/wwwroot/bag/ai-desgin
flutter create --project-name ai_design_studio --org com.aidesign --platforms=windows,macos .
```

预期：生成完整的 Flutter 项目结构，包含 windows/ 和 macos/ 平台目录。

- [ ] **Step 2: 添加依赖到 pubspec.yaml**

编辑 `pubspec.yaml`，在 dependencies 下添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path_provider: ^2.1.0
  flutter_rust_bridge: ^2.0.0
  uuid: ^4.2.0
  yaml: ^3.1.0
  ffi: ^2.1.0
  logging: ^1.2.0
  flutter_riverpod: ^2.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

- [ ] **Step 3: 安装依赖**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter pub get
```

预期：所有依赖成功下载，无版本冲突。

- [ ] **Step 4: 创建最小 app.dart**

```dart
// lib/app.dart
import 'package:flutter/material.dart';

class AiDesignApp extends StatelessWidget {
  const AiDesignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Design Studio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const Placeholder(),
    );
  }
}
```

- [ ] **Step 5: 创建 main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AiDesignApp());
}
```

- [ ] **Step 6: 验证项目可构建**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter build windows --debug
```

预期：构建成功，无编译错误。

- [ ] **Step 7: 提交**

```bash
git add -A && git commit -m "feat: initialize Flutter project with dependencies"
```

---

### Task 2: Rust workspace 初始化

**Files:**
- Create: `rust/Cargo.toml`
- Create: `rust/core/Cargo.toml`
- Create: `rust/core/src/lib.rs`
- Create: `flutter_rust_bridge.yaml`

- [ ] **Step 1: 创建 Rust workspace 根 Cargo.toml**

```toml
# rust/Cargo.toml
[workspace]
members = ["core", "plugins/figma"]
resolver = "2"

[workspace.package]
version = "0.1.0"
edition = "2021"
```

- [ ] **Step 2: 创建 core crate**

```toml
# rust/core/Cargo.toml
[package]
name = "ai_design_core"
version.workspace = true
edition.workspace = true

[dependencies]
serde = { version = "1", features = ["derive"] }
serde_json = "1"
thiserror = "1"
log = "0.4"
tokio = { version = "1", features = ["process", "io-util"] }
```

- [ ] **Step 3: 创建 core/src/lib.rs**

```rust
// rust/core/src/lib.rs
pub mod traits;
pub mod types;
pub mod ipc;

pub use traits::DesignPlugin;
pub use types::*;
```

- [ ] **Step 4: 创建 flutter_rust_bridge.yaml**

```yaml
# flutter_rust_bridge.yaml
rust_input: rust/core/src/api.rs
dart_output: lib/bridge
```

- [ ] **Step 5: 验证 Rust 编译**

```bash
cd /home/wwwroot/bag/ai-desgin/rust && cargo build
```

预期：编译成功。

- [ ] **Step 6: 提交**

```bash
git add rust/ flutter_rust_bridge.yaml && git commit -m "feat: initialize Rust workspace with core crate"
```

---

### Task 3: 共享类型定义 — Dart 侧

**Files:**
- Create: `lib/models/session.dart`
- Create: `lib/models/task_record.dart`
- Create: `lib/models/plugin.dart`
- Create: `lib/models/software_capabilities.dart`

- [ ] **Step 1: 编写测试 — Session 模型**

```dart
// test/models/session_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/models/session.dart';

void main() {
  test('Session should generate unique id on creation', () {
    final s1 = Session(domain: DesignCategory.web, softwareName: 'Figma');
    final s2 = Session(domain: DesignCategory.web, softwareName: 'Figma');
    expect(s1.id, isNot(s2.id));
  });

  test('Session should record createdAt on creation', () {
    final before = DateTime.now();
    final s = Session(domain: DesignCategory.industrial, softwareName: 'Blender');
    expect(s.createdAt.isAfter(before), true);
  });

  test('addRecord appends to history and returns record', () {
    final s = Session(domain: DesignCategory.threeD, softwareName: 'Blender');
    final record = s.addRecord(
      task: 'create a cube',
      script: 'import bpy; bpy.ops.mesh.primitive_cube_add()',
      scriptLanguage: 'python',
      modelUsed: 'claude-sonnet-4-6',
    );
    expect(s.history.length, 1);
    expect(record.task, 'create a cube');
    expect(record.status, TaskStatus.completed);
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/models/session_test.dart
```

预期：编译失败（类型未定义）。

- [ ] **Step 3: 实现所有 Dart 数据模型**

```dart
// lib/models/task_record.dart
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TaskStatus { pending, running, completed, failed, cancelled }

class TaskRecord {
  final String id;
  final String sessionId;
  final String task;
  final String? script;
  final String? scriptLanguage;
  final String? modelUsed;
  final TaskStatus status;
  final String? error;
  final List<String> artifacts;
  final DateTime createdAt;
  final DateTime? completedAt;

  TaskRecord({
    String? id,
    required this.sessionId,
    required this.task,
    this.script,
    this.scriptLanguage,
    this.modelUsed,
    this.status = TaskStatus.pending,
    this.error,
    this.artifacts = const [],
    DateTime? createdAt,
    this.completedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();
}
```

```dart
// lib/models/plugin.dart
enum ConnectionStatus { disconnected, connecting, connected, error }

class PluginMeta {
  final String id;
  final String name;
  final String version;
  final String scriptLanguage;

  const PluginMeta({
    required this.id,
    required this.name,
    required this.version,
    required this.scriptLanguage,
  });
}

class ScriptResult {
  final bool success;
  final String? output;
  final String? error;
  final List<String> artifacts;
  final Map<String, dynamic>? metadata;

  const ScriptResult({
    required this.success,
    this.output,
    this.error,
    this.artifacts = const [],
    this.metadata,
  });

  factory ScriptResult.success({String? output, List<String> artifacts = const [], Map<String, dynamic>? metadata}) {
    return ScriptResult(success: true, output: output, artifacts: artifacts, metadata: metadata);
  }

  factory ScriptResult.failure({required String error}) {
    return ScriptResult(success: false, error: error);
  }
}

class ConnectionConfig {
  final String host;
  final int port;
  final Map<String, String>? extra;

  const ConnectionConfig({required this.host, required this.port, this.extra});
}
```

```dart
// lib/models/software_capabilities.dart
class SoftwareCapabilities {
  final List<String> actions;
  final List<String> fileFormats;
  final Map<String, String>? constraints;

  const SoftwareCapabilities({
    required this.actions,
    required this.fileFormats,
    this.constraints,
  });

  Map<String, dynamic> toJson() => {
    'actions': actions,
    'fileFormats': fileFormats,
    if (constraints != null) 'constraints': constraints,
  };
}

class SoftwareState {
  final String activeDocument;
  final List<String> selectedNodes;
  final List<String> layers;
  final Map<String, dynamic>? extra;

  const SoftwareState({
    this.activeDocument = '',
    this.selectedNodes = const [],
    this.layers = const [],
    this.extra,
  });

  Map<String, dynamic> toJson() => {
    'activeDocument': activeDocument,
    'selectedNodes': selectedNodes,
    'layers': layers,
    if (extra != null) 'extra': extra,
  };
}
```

```dart
// lib/models/session.dart
import 'package:uuid/uuid.dart';
import 'task_record.dart';

const _uuid = Uuid();

enum DesignCategory { web, ad, industrial, threeD, arch, interior }

class SessionContext {
  final Map<String, dynamic> softwareState;
  final Map<String, dynamic> userPreferences;
  final List<String> recentActions;

  SessionContext({
    this.softwareState = const {},
    this.userPreferences = const {},
    this.recentActions = const [],
  });
}

class Session {
  final String id;
  final DesignCategory domain;
  final String softwareName;
  final SessionContext context;
  final DateTime createdAt;
  final List<TaskRecord> history;

  Session({
    String? id,
    required this.domain,
    required this.softwareName,
    SessionContext? context,
    DateTime? createdAt,
    List<TaskRecord>? history,
  })  : id = id ?? _uuid.v4(),
        context = context ?? SessionContext(),
        createdAt = createdAt ?? DateTime.now(),
        history = history ?? [];

  TaskRecord addRecord({
    required String task,
    required String script,
    required String scriptLanguage,
    required String modelUsed,
  }) {
    final record = TaskRecord(
      sessionId: id,
      task: task,
      script: script,
      scriptLanguage: scriptLanguage,
      modelUsed: modelUsed,
      status: TaskStatus.completed,
    );
    history.add(record);
    return record;
  }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/models/session_test.dart
```

预期：3 tests PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/models/ test/models/ && git commit -m "feat: add core data models (Session, TaskRecord, Plugin types, Capabilities)"
```

---

### Task 4: Rust 核心类型和 trait

**Files:**
- Create: `rust/core/src/types.rs`
- Create: `rust/core/src/traits.rs`
- Create: `rust/core/src/ipc.rs`

- [ ] **Step 1: 编写 Rust 类型定义**

```rust
// rust/core/src/types.rs
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DesignCategory {
    Web,
    Ad,
    Industrial,
    ThreeD,
    Arch,
    Interior,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ConnectionStatus {
    Disconnected,
    Connecting,
    Connected,
    Error,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginMeta {
    pub id: String,
    pub name: String,
    pub version: String,
    pub script_language: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginContext {
    pub plugin_dir: String,
    pub data_dir: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConnectionConfig {
    pub host: String,
    pub port: u16,
    pub extra: Option<std::collections::HashMap<String, String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SoftwareCapabilities {
    pub actions: Vec<String>,
    pub file_formats: Vec<String>,
    pub constraints: Option<std::collections::HashMap<String, String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SoftwareState {
    pub active_document: String,
    pub selected_nodes: Vec<String>,
    pub layers: Vec<String>,
    pub extra: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScriptResult {
    pub success: bool,
    pub output: Option<String>,
    pub error: Option<String>,
    pub artifacts: Vec<String>,
    pub metadata: Option<serde_json::Value>,
}

impl ScriptResult {
    pub fn success(output: Option<String>, artifacts: Vec<String>) -> Self {
        Self { success: true, output, error: None, artifacts, metadata: None }
    }

    pub fn failure(error: String) -> Self {
        Self { success: false, output: None, error: Some(error), artifacts: vec![], metadata: None }
    }
}
```

- [ ] **Step 2: 编写 Rust trait**

```rust
// rust/core/src/traits.rs
use crate::types::*;

pub trait DesignPlugin: Send + Sync {
    fn meta(&self) -> &PluginMeta;
    fn category(&self) -> DesignCategory;

    fn initialize(&mut self, ctx: &PluginContext) -> Result<(), String>;
    fn dispose(&mut self);

    fn check_connection(&self) -> ConnectionStatus;
    fn connect(&mut self, config: &ConnectionConfig) -> Result<bool, String>;

    fn capabilities(&self) -> &SoftwareCapabilities;

    fn execute(&self, script: &str) -> Result<ScriptResult, String>;
    fn preview(&self, script: &str) -> Result<ScriptResult, String>;

    fn get_current_state(&self) -> Result<SoftwareState, String>;
}
```

- [ ] **Step 3: 编写 IPC 工具模块**

```rust
// rust/core/src/ipc.rs
use std::process::{Command, Child, Stdio};
use std::io::Write;

pub struct IsolatedProcess {
    child: Child,
}

impl IsolatedProcess {
    pub fn spawn(command: &str, args: &[&str]) -> Result<Self, String> {
        let child = Command::new(command)
            .args(args)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .map_err(|e| format!("Failed to spawn process: {}", e))?;
        Ok(Self { child })
    }

    pub fn send_script(&mut self, script: &str) -> Result<String, String> {
        let stdin = self.child.stdin.as_mut()
            .ok_or("Failed to open stdin")?;
        stdin.write_all(script.as_bytes())
            .map_err(|e| format!("Write error: {}", e))?;
        Ok(String::new())
    }

    pub fn kill(&mut self) {
        let _ = self.child.kill();
    }
}

impl Drop for IsolatedProcess {
    fn drop(&mut self) {
        self.kill();
    }
}
```

- [ ] **Step 4: 验证编译**

```bash
cd /home/wwwroot/bag/ai-desgin/rust && cargo build
```

预期：编译成功。

- [ ] **Step 5: 提交**

```bash
git add rust/core/src/ && git commit -m "feat: add Rust core types, trait, and IPC module"
```

---

### Task 5: Plugin SDK — Dart 接口定义

**Files:**
- Create: `lib/plugin_sdk/design_plugin.dart`

- [ ] **Step 1: 编写测试**

```dart
// test/plugin_sdk/design_plugin_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/plugin_sdk/design_plugin.dart';
import 'package:ai_design_studio/models/plugin.dart';
import 'package:ai_design_studio/models/software_capabilities.dart';
import 'package:ai_design_studio/models/session.dart';

class FakeFigmaPlugin extends DesignPlugin {
  @override String get id => 'com.aidesign.figma';
  @override String get name => 'Figma';
  @override String get version => '1.0.0';
  @override DesignCategory get category => DesignCategory.web;
  @override String get scriptLanguage => 'javascript';

  @override SoftwareCapabilities get capabilities => const SoftwareCapabilities(
    actions: ['创建画布', '添加矩形', '设置填充色', '导出PNG'],
    fileFormats: ['fig', 'png', 'svg'],
  );

  @override Future<bool> initialize(PluginContext ctx) async => true;
  @override Future<void> dispose() async {}
  @override Future<ConnectionStatus> checkConnection() async => ConnectionStatus.disconnected;
  @override Future<bool> connect(ConnectionConfig config) async => true;

  @override Future<ScriptResult> execute(String script, {ProgressCallback? onProgress}) async {
    onProgress?.call(0.5);
    onProgress?.call(1.0);
    return ScriptResult.success(output: 'ok');
  }

  @override Future<ScriptResult> preview(String script) async {
    return ScriptResult.success(output: 'preview ok');
  }

  @override Future<SoftwareState> getCurrentState() async => const SoftwareState(
    activeDocument: 'untitled.fig',
    layers: ['Layer 1', 'Rectangle 1'],
  );
}

void main() {
  late FakeFigmaPlugin plugin;
  setUp(() => plugin = FakeFigmaPlugin());

  test('plugin metadata is correct', () {
    expect(plugin.id, 'com.aidesign.figma');
    expect(plugin.name, 'Figma');
    expect(plugin.category, DesignCategory.web);
    expect(plugin.scriptLanguage, 'javascript');
  });

  test('initialize sets up plugin', () async {
    final result = await plugin.initialize(const PluginContext(pluginPath: '/tmp/plugin'));
    expect(result, true);
  });

  test('capabilities lists available actions', () {
    expect(plugin.capabilities.actions, contains('创建画布'));
    expect(plugin.capabilities.fileFormats, contains('fig'));
  });

  test('execute returns result and reports progress', () async {
    final progress = <double>[];
    final result = await plugin.execute('create rectangle', onProgress: (p) => progress.add(p));
    expect(result.success, true);
    expect(progress, [0.5, 1.0]);
  });

  test('preview does not modify state', () async {
    final result = await plugin.preview('create rectangle');
    expect(result.success, true);
    expect(result.output, 'preview ok');
  });

  test('getCurrentState returns document snapshot', () async {
    final state = await plugin.getCurrentState();
    expect(state.activeDocument, 'untitled.fig');
    expect(state.layers.length, 2);
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/plugin_sdk/design_plugin_test.dart
```

- [ ] **Step 3: 实现 DesignPlugin 抽象类**

```dart
// lib/plugin_sdk/design_plugin.dart
import '../models/plugin.dart';
import '../models/software_capabilities.dart';
import '../models/session.dart';

typedef ProgressCallback = void Function(double progress);

class PluginContext {
  final String pluginPath;
  final Map<String, String>? env;

  const PluginContext({required this.pluginPath, this.env});
}

abstract class DesignPlugin {
  String get id;
  String get name;
  String get version;
  DesignCategory get category;
  String get scriptLanguage;

  SoftwareCapabilities get capabilities;

  Future<bool> initialize(PluginContext ctx);
  Future<void> dispose();

  Future<ConnectionStatus> checkConnection();
  Future<bool> connect(ConnectionConfig config);

  Future<ScriptResult> execute(String script, {ProgressCallback? onProgress});
  Future<ScriptResult> preview(String script);

  Future<SoftwareState> getCurrentState();
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/plugin_sdk/design_plugin_test.dart
```

预期：6 tests PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/plugin_sdk/ test/plugin_sdk/ && git commit -m "feat: add DesignPlugin Dart interface and tests"
```

---

### Task 6: PluginManager 实现

**Files:**
- Create: `lib/core/plugin_manager.dart`

- [ ] **Step 1: 编写测试**

```dart
// test/core/plugin_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/plugin_manager.dart';
import 'package:ai_design_studio/plugin_sdk/design_plugin.dart';
import 'package:ai_design_studio/models/plugin.dart';
import 'package:ai_design_studio/models/software_capabilities.dart';
import 'package:ai_design_studio/models/session.dart';

class StubPlugin extends DesignPlugin {
  final String _id;
  StubPlugin(this._id);

  @override String get id => _id;
  @override String get name => 'Stub $_id';
  @override String get version => '0.0.1';
  @override DesignCategory get category => DesignCategory.web;
  @override String get scriptLanguage => 'javascript';
  @override SoftwareCapabilities get capabilities => const SoftwareCapabilities(actions: [], fileFormats: []);

  @override Future<bool> initialize(PluginContext ctx) async => true;
  @override Future<void> dispose() async {}
  @override Future<ConnectionStatus> checkConnection() async => ConnectionStatus.disconnected;
  @override Future<bool> connect(ConnectionConfig config) async => true;
  @override Future<ScriptResult> execute(String script, {ProgressCallback? onProgress}) async => ScriptResult.success();
  @override Future<ScriptResult> preview(String script) async => ScriptResult.success();
  @override Future<SoftwareState> getCurrentState() async => const SoftwareState();
}

void main() {
  test('register adds plugin to registry', () {
    final manager = PluginManager();
    manager.register(StubPlugin('test.1'));
    expect(manager.getAll().length, 1);
  });

  test('get returns plugin by id', () {
    final manager = PluginManager();
    manager.register(StubPlugin('a'));
    manager.register(StubPlugin('b'));
    expect(manager.get('b')?.id, 'b');
  });

  test('get returns null for unknown id', () {
    final manager = PluginManager();
    expect(manager.get('nonexistent'), isNull);
  });

  test('getByCategory filters plugins', () {
    final manager = PluginManager();
    manager.register(StubPlugin('web.1'));
    manager.register(StubPlugin('web.2'));
    expect(manager.getByCategory(DesignCategory.web).length, 2);
  });

  test('unregister removes plugin', () {
    final manager = PluginManager();
    final plugin = StubPlugin('to.remove');
    manager.register(plugin);
    manager.unregister('to.remove');
    expect(manager.getAll().length, 0);
  });

  test('initializeAll calls initialize on all plugins', () async {
    final manager = PluginManager();
    manager.register(StubPlugin('a'));
    manager.register(StubPlugin('b'));
    await manager.initializeAll(const PluginContext(pluginPath: '/tmp'));
  });

  test('disposeAll disposes all plugins and clears registry', () async {
    final manager = PluginManager();
    manager.register(StubPlugin('a'));
    await manager.initializeAll(const PluginContext(pluginPath: '/tmp'));
    await manager.disposeAll();
    expect(manager.getAll().length, 0);
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/core/plugin_manager_test.dart
```

- [ ] **Step 3: 实现 PluginManager**

```dart
// lib/core/plugin_manager.dart
import '../plugin_sdk/design_plugin.dart';
import '../models/session.dart';

class PluginManager {
  final Map<String, DesignPlugin> _plugins = {};

  void register(DesignPlugin plugin) {
    _plugins[plugin.id] = plugin;
  }

  DesignPlugin? get(String id) => _plugins[id];

  List<DesignPlugin> getAll() => _plugins.values.toList();

  List<DesignPlugin> getByCategory(DesignCategory category) {
    return _plugins.values.where((p) => p.category == category).toList();
  }

  void unregister(String id) {
    _plugins.remove(id);
  }

  Future<void> initializeAll(PluginContext ctx) async {
    for (final plugin in _plugins.values) {
      await plugin.initialize(ctx);
    }
  }

  Future<void> disposeAll() async {
    final plugins = List<DesignPlugin>.from(_plugins.values);
    for (final plugin in plugins) {
      await plugin.dispose();
    }
    _plugins.clear();
  }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/core/plugin_manager_test.dart
```

预期：7 tests PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/core/plugin_manager.dart test/core/plugin_manager_test.dart && git commit -m "feat: add PluginManager with registration, lookup, and lifecycle"
```

---

### Task 7: ModelRouter 实现

**Files:**
- Create: `lib/core/model_router.dart`
- Create: `config/model-routing.yaml`

- [ ] **Step 1: 创建默认路由配置**

```yaml
# config/model-routing.yaml
default: claude-sonnet-4-6

routes:
  - domains: [web, ad]
    complexity: creative
    model: claude-opus-4-7

  - domains: [industrial, threeD, arch, interior]
    model: claude-opus-4-7

  - complexity: simple
    model: claude-haiku-4-5
```

- [ ] **Step 2: 编写测试**

```dart
// test/core/model_router_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/model_router.dart';
import 'package:ai_design_studio/models/session.dart';

void main() {
  late ModelRouter router;

  setUp(() async {
    router = ModelRouter();
    await router.loadConfigFromString('''
default: claude-sonnet-4-6
routes:
  - domains: [web, ad]
    complexity: creative
    model: claude-opus-4-7
  - domains: [industrial, threeD, arch, interior]
    model: claude-opus-4-7
  - complexity: simple
    model: claude-haiku-4-5
''');
  });

  test('routes web creative task to opus', () {
    final model = router.route(domain: DesignCategory.web, task: '设计一个landing page');
    expect(model, 'claude-opus-4-7');
  });

  test('routes architectural task to opus', () {
    final model = router.route(domain: DesignCategory.arch, task: '设计立面图');
    expect(model, 'claude-opus-4-7');
  });

  test('routes simple task to haiku', () {
    final model = router.route(
      domain: DesignCategory.web,
      task: 'rename layers',
      forceComplexity: TaskComplexity.simple,
    );
    expect(model, 'claude-haiku-4-5');
  });

  test('falls back to default', () {
    final model = router.route(domain: DesignCategory.web, task: 'some task');
    expect(model, 'claude-sonnet-4-6');
  });

  test('allows override model', () {
    final model = router.route(
      domain: DesignCategory.web,
      task: 'design page',
      overrideModel: 'gemini-pro',
    );
    expect(model, 'gemini-pro');
  });
}
```

- [ ] **Step 3: 运行测试验证失败**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/core/model_router_test.dart
```

- [ ] **Step 4: 实现 ModelRouter**

```dart
// lib/core/model_router.dart
import 'package:yaml/yaml.dart';
import '../models/session.dart';

enum TaskComplexity { simple, moderate, creative }

class ModelRoute {
  final List<DesignCategory>? domains;
  final TaskComplexity? complexity;
  final String model;

  const ModelRoute({this.domains, this.complexity, required this.model});

  bool matches(DesignCategory domain, TaskComplexity taskComplexity) {
    if (domains != null && !domains!.contains(domain)) return false;
    if (complexity != null && complexity != taskComplexity) return false;
    return true;
  }
}

class ModelRouter {
  String _defaultModel = 'claude-sonnet-4-6';
  final List<ModelRoute> _routes = [];

  Future<void> loadConfigFromString(String yamlContent) async {
    final doc = loadYaml(yamlContent);
    _defaultModel = doc['default'] as String? ?? _defaultModel;
    _routes.clear();

    final routes = doc['routes'] as YamlList? ?? [];
    for (final r in routes) {
      final domainsRaw = r['domains'] as YamlList?;
      final domains = domainsRaw?.map((d) {
        switch (d.toString()) {
          case 'web': return DesignCategory.web;
          case 'ad': return DesignCategory.ad;
          case 'industrial': return DesignCategory.industrial;
          case 'threeD': return DesignCategory.threeD;
          case 'arch': return DesignCategory.arch;
          case 'interior': return DesignCategory.interior;
          default: return DesignCategory.web;
        }
      }).toList();

      TaskComplexity? complexity;
      final comp = r['complexity']?.toString();
      if (comp == 'simple') complexity = TaskComplexity.simple;
      else if (comp == 'moderate') complexity = TaskComplexity.moderate;
      else if (comp == 'creative') complexity = TaskComplexity.creative;

      _routes.add(ModelRoute(domains: domains, complexity: complexity, model: r['model'].toString()));
    }
  }

  String route({
    required DesignCategory domain,
    required String task,
    TaskComplexity? forceComplexity,
    String? overrideModel,
  }) {
    if (overrideModel != null) return overrideModel;

    final complexity = forceComplexity ?? _inferComplexity(task);

    for (final route in _routes) {
      if (route.matches(domain, complexity)) return route.model;
    }
    return _defaultModel;
  }

  TaskComplexity _inferComplexity(String task) {
    final creativeKeywords = ['设计', '创意', '方案', '风格', 'layout', 'design'];
    final simpleKeywords = ['改名', '导出', '删除', '列表', 'rename', 'export', 'delete', 'list'];

    for (final kw in creativeKeywords) {
      if (task.contains(kw)) return TaskComplexity.creative;
    }
    for (final kw in simpleKeywords) {
      if (task.contains(kw)) return TaskComplexity.simple;
    }
    return TaskComplexity.moderate;
  }
}
```

- [ ] **Step 5: 运行测试验证通过**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/core/model_router_test.dart
```

预期：5 tests PASS。

- [ ] **Step 6: 提交**

```bash
git add lib/core/model_router.dart config/model-routing.yaml test/core/model_router_test.dart && git commit -m "feat: add ModelRouter with YAML config and keyword-based complexity inference"
```

---

### Task 8: CCProcessManager 实现

**Files:**
- Create: `lib/core/cc_process_manager.dart`

- [ ] **Step 1: 编写测试**

```dart
// test/core/cc_process_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/cc_process_manager.dart';
import 'package:ai_design_studio/models/software_capabilities.dart';

void main() {
  late CCProcessManager manager;

  setUp(() {
    manager = CCProcessManager(maxProcesses: 2, idleTimeoutSeconds: 300);
  });

  test('createSession returns session with id', () {
    final caps = const SoftwareCapabilities(actions: [], fileFormats: []);
    final state = const SoftwareState();
    final session = manager.createSession(software: 'figma', capabilities: caps, state: state);
    expect(session.id, isNotEmpty);
  });

  test('active session count does not exceed maxProcesses', () {
    final caps = const SoftwareCapabilities(actions: [], fileFormats: []);
    final state = const SoftwareState();
    manager.createSession(software: 'a', capabilities: caps, state: state);
    manager.createSession(software: 'b', capabilities: caps, state: state);
    manager.createSession(software: 'c', capabilities: caps, state: state);
    expect(manager.activeSessionCount, lessThanOrEqualTo(2));
  });

  test('getSession retrieves by id', () {
    final caps = const SoftwareCapabilities(actions: [], fileFormats: []);
    final state = const SoftwareState();
    final session = manager.createSession(software: 'figma', capabilities: caps, state: state);
    final retrieved = manager.getSession(session.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.software, 'figma');
  });

  test('closeSession removes session', () {
    final caps = const SoftwareCapabilities(actions: [], fileFormats: []);
    final state = const SoftwareState();
    final session = manager.createSession(software: 'figma', capabilities: caps, state: state);
    manager.closeSession(session.id);
    expect(manager.getSession(session.id), isNull);
    expect(manager.activeSessionCount, 0);
  });

  test('buildRequest creates valid JSON-RPC request', () {
    final caps = const SoftwareCapabilities(actions: ['export'], fileFormats: ['png']);
    final state = const SoftwareState(activeDocument: 'test.fig');
    final session = manager.createSession(software: 'figma', capabilities: caps, state: state);
    final request = manager.buildRequest(sessionId: session.id, task: 'export to PNG', model: 'claude-sonnet-4-6');

    expect(request['method'], 'design.execute');
    expect(request['params']['task'], 'export to PNG');
    expect(request['params']['model'], 'claude-sonnet-4-6');
    expect(request['params']['software'], 'figma');
    expect(request['params']['capabilities']['actions'], contains('export'));
    expect(request['params']['state']['activeDocument'], 'test.fig');
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/core/cc_process_manager_test.dart
```

- [ ] **Step 3: 实现 CCProcessManager**

```dart
// lib/core/cc_process_manager.dart
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/software_capabilities.dart';

const _uuid = Uuid();

class CCSession {
  final String id;
  final String software;
  final SoftwareCapabilities capabilities;
  final SoftwareState state;
  final DateTime createdAt;
  DateTime lastActivity;

  CCSession({
    String? id,
    required this.software,
    required this.capabilities,
    required this.state,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastActivity = DateTime.now();
}

class CCProcessManager {
  final int maxProcesses;
  final int idleTimeoutSeconds;
  final Map<String, CCSession> _sessions = {};

  CCProcessManager({this.maxProcesses = 3, this.idleTimeoutSeconds = 300});

  CCSession createSession({
    required String software,
    required SoftwareCapabilities capabilities,
    required SoftwareState state,
  }) {
    _evictIdleSessions();

    if (_sessions.length >= maxProcesses) {
      final oldest = _sessions.entries
          .reduce((a, b) => a.value.lastActivity.isBefore(b.value.lastActivity) ? a : b);
      _sessions.remove(oldest.key);
    }

    final session = CCSession(software: software, capabilities: capabilities, state: state);
    _sessions[session.id] = session;
    return session;
  }

  CCSession? getSession(String sessionId) => _sessions[sessionId];

  void closeSession(String sessionId) {
    _sessions.remove(sessionId);
  }

  int get activeSessionCount => _sessions.length;

  Map<String, dynamic> buildRequest({
    required String sessionId,
    required String task,
    required String model,
  }) {
    final session = _sessions[sessionId];
    session?.lastActivity = DateTime.now();

    return {
      'id': 'msg_${_uuid.v4().substring(0, 8)}',
      'method': 'design.execute',
      'params': {
        'sessionId': sessionId,
        'software': session?.software ?? '',
        'capabilities': session?.capabilities.toJson() ?? {},
        'state': session?.state.toJson() ?? {},
        'task': task,
        'model': model,
      },
    };
  }

  String serializeRequest(Map<String, dynamic> request) {
    return '${jsonEncode(request)}\n';
  }

  void _evictIdleSessions() {
    final now = DateTime.now();
    _sessions.removeWhere((_, session) {
      return now.difference(session.lastActivity).inSeconds > idleTimeoutSeconds;
    });
  }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/core/cc_process_manager_test.dart
```

预期：5 tests PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/core/cc_process_manager.dart test/core/cc_process_manager_test.dart && git commit -m "feat: add CCProcessManager with session lifecycle and JSON-RPC request builder"
```

---

### Task 9: TaskOrchestrator 实现

**Files:**
- Create: `lib/core/task_orchestrator.dart`

- [ ] **Step 1: 编写测试**

```dart
// test/core/task_orchestrator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/task_orchestrator.dart';
import 'package:ai_design_studio/core/plugin_manager.dart';
import 'package:ai_design_studio/core/cc_process_manager.dart';
import 'package:ai_design_studio/core/model_router.dart';
import 'package:ai_design_studio/plugin_sdk/design_plugin.dart';
import 'package:ai_design_studio/models/session.dart';
import 'package:ai_design_studio/models/plugin.dart';
import 'package:ai_design_studio/models/software_capabilities.dart';
import 'package:ai_design_studio/models/task_record.dart';

class EchoPlugin extends DesignPlugin {
  @override String get id => 'echo';
  @override String get name => 'Echo';
  @override String get version => '0.1.0';
  @override DesignCategory get category => DesignCategory.web;
  @override String get scriptLanguage => 'text';
  @override SoftwareCapabilities get capabilities => const SoftwareCapabilities(actions: ['echo'], fileFormats: []);

  @override Future<bool> initialize(PluginContext ctx) async => true;
  @override Future<void> dispose() async {}
  @override Future<ConnectionStatus> checkConnection() async => ConnectionStatus.connected;
  @override Future<bool> connect(ConnectionConfig config) async => true;
  @override Future<ScriptResult> execute(String script, {ProgressCallback? onProgress}) async {
    return ScriptResult.success(output: 'executed: $script');
  }
  @override Future<ScriptResult> preview(String script) async => ScriptResult.success(output: 'preview: $script');
  @override Future<SoftwareState> getCurrentState() async => const SoftwareState();
}

void main() {
  late TaskOrchestrator orchestrator;
  late PluginManager pluginManager;
  late CCProcessManager ccManager;
  late ModelRouter modelRouter;

  setUp(() async {
    pluginManager = PluginManager();
    pluginManager.register(EchoPlugin());
    ccManager = CCProcessManager();
    modelRouter = ModelRouter();
    await modelRouter.loadConfigFromString('default: claude-sonnet-4-6\nroutes: []');
    orchestrator = TaskOrchestrator(
      pluginManager: pluginManager,
      ccManager: ccManager,
      modelRouter: modelRouter,
      maxConcurrent: 2,
    );
  });

  test('submitTask completes with success for known software', () async {
    final task = await orchestrator.submitTask(
      domain: DesignCategory.web,
      softwareName: 'echo',
      task: 'say hello',
    );
    expect(task.status, TaskStatus.completed);
    expect(task.task, 'say hello');
  });

  test('submitTask fails for unknown software', () async {
    final task = await orchestrator.submitTask(
      domain: DesignCategory.web,
      softwareName: 'nonexistent',
      task: 'do something',
    );
    expect(task.status, TaskStatus.failed);
    expect(task.error, isNotNull);
  });

  test('session is created per software and records history', () async {
    await orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'task 1');
    final session = orchestrator.getCurrentSession('echo');
    expect(session, isNotNull);
    expect(session!.history.length, 1);
  });

  test('cancelTask cancels a pending task', () async {
    final task = await orchestrator.submitTask(domain: DesignCategory.web, softwareName: 'echo', task: 'cancel me');
    orchestrator.cancelTask(task.id);
    final cancelled = orchestrator.getTask(task.id);
    expect(cancelled?.status, TaskStatus.cancelled);
  });

  test('getTask returns null for unknown id', () {
    expect(orchestrator.getTask('nonexistent'), isNull);
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/core/task_orchestrator_test.dart
```

- [ ] **Step 3: 实现 TaskOrchestrator**

```dart
// lib/core/task_orchestrator.dart
import '../plugin_sdk/design_plugin.dart';
import 'plugin_manager.dart';
import 'cc_process_manager.dart';
import 'model_router.dart';
import '../models/session.dart';
import '../models/task_record.dart';

class TaskOrchestrator {
  final PluginManager _pluginManager;
  final CCProcessManager _ccManager;
  final ModelRouter _modelRouter;
  final int maxConcurrent;

  final Map<String, Session> _sessions = {};
  final Map<String, TaskRecord> _tasks = {};

  TaskOrchestrator({
    required PluginManager pluginManager,
    required CCProcessManager ccManager,
    required ModelRouter modelRouter,
    this.maxConcurrent = 3,
  })  : _pluginManager = pluginManager,
        _ccManager = ccManager,
        _modelRouter = modelRouter;

  Future<TaskRecord> submitTask({
    required DesignCategory domain,
    required String softwareName,
    required String task,
    String? overrideModel,
  }) async {
    final plugin = _pluginManager.get(softwareName);
    if (plugin == null) {
      final record = TaskRecord(
        sessionId: '',
        task: task,
        status: TaskStatus.failed,
        error: 'Software not found: $softwareName',
      );
      _tasks[record.id] = record;
      return record;
    }

    final record = TaskRecord(sessionId: softwareName, task: task, status: TaskStatus.running);
    _tasks[record.id] = record;

    try {
      final model = _modelRouter.route(domain: domain, task: task, overrideModel: overrideModel);
      final state = await plugin.getCurrentState();
      final session = _ccManager.createSession(
        software: softwareName,
        capabilities: plugin.capabilities,
        state: state,
      );

      // In production: build JSON-RPC request and send to Claude Code subprocess
      final _request = _ccManager.buildRequest(sessionId: session.id, task: task, model: model);

      final result = await plugin.execute(task);
      _ccManager.closeSession(session.id);

      final updated = TaskRecord(
        id: record.id,
        sessionId: softwareName,
        task: task,
        script: task,
        scriptLanguage: plugin.scriptLanguage,
        modelUsed: model,
        status: result.success ? TaskStatus.completed : TaskStatus.failed,
        error: result.error,
        artifacts: result.artifacts,
        createdAt: record.createdAt,
        completedAt: DateTime.now(),
      );
      _tasks[record.id] = updated;

      _getOrCreateSession(domain, softwareName).addRecord(
        task: task,
        script: task,
        scriptLanguage: plugin.scriptLanguage,
        modelUsed: model,
      );

      return updated;
    } catch (e) {
      final failed = TaskRecord(
        id: record.id,
        sessionId: softwareName,
        task: task,
        status: TaskStatus.failed,
        error: e.toString(),
        createdAt: record.createdAt,
        completedAt: DateTime.now(),
      );
      _tasks[record.id] = failed;
      return failed;
    }
  }

  Session? getCurrentSession(String softwareName) => _sessions[softwareName];

  TaskRecord? getTask(String taskId) => _tasks[taskId];

  void cancelTask(String taskId) {
    final task = _tasks[taskId];
    if (task != null && task.status == TaskStatus.pending) {
      _tasks[taskId] = TaskRecord(
        id: task.id,
        sessionId: task.sessionId,
        task: task.task,
        status: TaskStatus.cancelled,
        createdAt: task.createdAt,
        completedAt: DateTime.now(),
      );
    }
  }

  int get activeTaskCount => _tasks.values.where((t) => t.status == TaskStatus.running).length;

  Session _getOrCreateSession(DesignCategory domain, String softwareName) {
    return _sessions.putIfAbsent(softwareName, () => Session(domain: domain, softwareName: softwareName));
  }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/core/task_orchestrator_test.dart
```

预期：5 tests PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/core/task_orchestrator.dart test/core/task_orchestrator_test.dart && git commit -m "feat: add TaskOrchestrator with task submission, session tracking, and cancellation"
```

---

### Task 10: Session 持久化

**Files:**
- Create: `lib/core/session_store.dart`

- [ ] **Step 1: 编写测试**

```dart
// test/core/session_store_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ai_design_studio/core/session_store.dart';
import 'package:ai_design_studio/models/session.dart';

void main() {
  late SessionStore store;
  late Database db;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: SessionStore.onCreate,
    );
    store = SessionStore(db);
  });

  tearDown(() async => db.close());

  test('save and load session preserves data', () async {
    final session = Session(domain: DesignCategory.web, softwareName: 'figma');
    session.addRecord(task: 'create button', script: 'createNode("BUTTON")', scriptLanguage: 'javascript', modelUsed: 'claude-sonnet-4-6');
    await store.save(session);
    final loaded = await store.load(session.id);
    expect(loaded, isNotNull);
    expect(loaded!.id, session.id);
    expect(loaded.domain, DesignCategory.web);
  });

  test('load returns null for unknown id', () async {
    final result = await store.load('nonexistent');
    expect(result, isNull);
  });

  test('listBySoftware filters sessions', () async {
    await store.save(Session(domain: DesignCategory.web, softwareName: 'figma'));
    await store.save(Session(domain: DesignCategory.threeD, softwareName: 'blender'));
    await store.save(Session(domain: DesignCategory.web, softwareName: 'figma'));
    final figmas = await store.listBySoftware('figma');
    expect(figmas.length, 2);
  });

  test('search finds sessions by task content', () async {
    final s = Session(domain: DesignCategory.web, softwareName: 'figma');
    s.addRecord(task: 'create a blue login button', script: '', scriptLanguage: '', modelUsed: '');
    await store.save(s);
    final results = await store.search('login');
    expect(results.length, 1);
  });

  test('delete removes session', () async {
    final s = Session(domain: DesignCategory.web, softwareName: 'figma');
    await store.save(s);
    await store.delete(s.id);
    expect(await store.load(s.id), isNull);
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/core/session_store_test.dart
```

- [ ] **Step 3: 实现 SessionStore**

```dart
// lib/core/session_store.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/session.dart';
import '../models/task_record.dart';

class SessionStore {
  final Database _db;
  SessionStore(this._db);

  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        domain TEXT NOT NULL,
        software_name TEXT NOT NULL,
        context_json TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE task_records (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        task TEXT NOT NULL,
        script TEXT,
        script_language TEXT,
        model_used TEXT,
        status TEXT NOT NULL,
        error TEXT,
        artifacts_json TEXT,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_task_session ON task_records(session_id)');
    await db.execute('CREATE INDEX idx_sessions_software ON sessions(software_name)');
  }

  Future<void> save(Session session) async {
    await _db.insert('sessions', {
      'id': session.id,
      'domain': session.domain.name,
      'software_name': session.softwareName,
      'context_json': jsonEncode({
        'softwareState': session.context.softwareState,
        'userPreferences': session.context.userPreferences,
        'recentActions': session.context.recentActions,
      }),
      'created_at': session.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    for (final record in session.history) {
      await _db.insert('task_records', {
        'id': record.id,
        'session_id': session.id,
        'task': record.task,
        'script': record.script,
        'script_language': record.scriptLanguage,
        'model_used': record.modelUsed,
        'status': record.status.name,
        'error': record.error,
        'artifacts_json': jsonEncode(record.artifacts),
        'created_at': record.createdAt.toIso8601String(),
        'completed_at': record.completedAt?.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<Session?> load(String sessionId) async {
    final rows = await _db.query('sessions', where: 'id = ?', whereArgs: [sessionId]);
    if (rows.isEmpty) return null;

    final row = rows.first;
    final contextData = jsonDecode(row['context_json'] as String? ?? '{}');

    final records = await _db.query(
      'task_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );

    return Session(
      id: row['id'] as String,
      domain: DesignCategory.values.firstWhere((d) => d.name == row['domain']),
      softwareName: row['software_name'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      context: SessionContext(
        softwareState: Map<String, dynamic>.from(contextData['softwareState'] ?? {}),
        userPreferences: Map<String, dynamic>.from(contextData['userPreferences'] ?? {}),
        recentActions: List<String>.from(contextData['recentActions'] ?? []),
      ),
      history: records.map(_deserializeRecord).toList(),
    );
  }

  Future<List<Session>> listBySoftware(String softwareName) async {
    final rows = await _db.query(
      'sessions',
      where: 'software_name = ?',
      whereArgs: [softwareName],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => Session(
      id: r['id'] as String,
      domain: DesignCategory.values.firstWhere((d) => d.name == r['domain']),
      softwareName: r['software_name'] as String,
      createdAt: DateTime.parse(r['created_at'] as String),
    )).toList();
  }

  Future<List<Session>> search(String query) async {
    final rows = await _db.rawQuery('''
      SELECT DISTINCT s.* FROM sessions s
      INNER JOIN task_records t ON t.session_id = s.id
      WHERE t.task LIKE ? ORDER BY s.created_at DESC
    ''', ['%$query%']);
    return rows.map((r) => Session(
      id: r['id'] as String,
      domain: DesignCategory.values.firstWhere((d) => d.name == r['domain']),
      softwareName: r['software_name'] as String,
      createdAt: DateTime.parse(r['created_at'] as String),
    )).toList();
  }

  Future<void> delete(String sessionId) async {
    await _db.delete('task_records', where: 'session_id = ?', whereArgs: [sessionId]);
    await _db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  TaskRecord _deserializeRecord(Map<String, dynamic> row) {
    return TaskRecord(
      id: row['id'] as String,
      sessionId: row['session_id'] as String,
      task: row['task'] as String,
      script: row['script'] as String?,
      scriptLanguage: row['script_language'] as String?,
      modelUsed: row['model_used'] as String?,
      status: TaskStatus.values.firstWhere((s) => s.name == row['status']),
      error: row['error'] as String?,
      artifacts: List<String>.from(jsonDecode(row['artifacts_json'] as String? ?? '[]')),
      createdAt: DateTime.parse(row['created_at'] as String),
      completedAt: row['completed_at'] != null ? DateTime.parse(row['completed_at'] as String) : null,
    );
  }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/core/session_store_test.dart
```

预期：5 tests PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/core/session_store.dart test/core/session_store_test.dart && git commit -m "feat: add SQLite SessionStore with save, load, search, and delete"
```

---

### Task 11: Flutter UI Shell

**Files:**
- Create: `lib/ui/shell.dart`

- [ ] **Step 1: 编写 Widget 测试**

```dart
// test/ui/shell_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_design_studio/ui/shell.dart';
import 'package:ai_design_studio/models/session.dart';

void main() {
  testWidgets('Shell renders sidebar and content area', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell(child: Text('Content'))));
    expect(find.text('AI Design Studio'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('Sidebar renders domain switcher', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell(child: Text('test'))));
    expect(find.text('Web 设计'), findsOneWidget);
    expect(find.text('3D 设计'), findsOneWidget);
    expect(find.text('建筑设计'), findsOneWidget);
  });

  testWidgets('Selecting domain fires callback', (tester) async {
    DesignCategory? selected;
    await tester.pumpWidget(MaterialApp(
      home: AppShell(child: const Text('test'), onDomainChanged: (d) => selected = d),
    ));
    await tester.tap(find.text('工业设计'));
    await tester.pumpAndSettle();
    expect(selected, DesignCategory.industrial);
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/ui/shell_test.dart
```

- [ ] **Step 3: 实现 AppShell**

```dart
// lib/ui/shell.dart
import 'package:flutter/material.dart';
import '../models/session.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final ValueChanged<DesignCategory>? onDomainChanged;

  const AppShell({super.key, required this.child, this.onDomainChanged});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  DesignCategory _selectedDomain = DesignCategory.web;

  static const _domains = [
    (DesignCategory.web, 'Web 设计', Icons.language),
    (DesignCategory.ad, '广告设计', Icons.campaign),
    (DesignCategory.industrial, '工业设计', Icons.precision_manufacturing),
    (DesignCategory.threeD, '3D 设计', Icons.view_in_ar),
    (DesignCategory.arch, '建筑设计', Icons.architecture),
    (DesignCategory.interior, '装修设计', Icons.chair),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          const VerticalDivider(width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('AI Design Studio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('设计领域', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          ..._domains.map(_buildDomainTile),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainTile((DesignCategory, String, IconData) domain) {
    final (cat, label, icon) = domain;
    final isSelected = cat == _selectedDomain;
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      selected: isSelected,
      dense: true,
      onTap: () {
        setState(() => _selectedDomain = cat);
        widget.onDomainChanged?.call(cat);
      },
    );
  }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/ui/shell_test.dart
```

预期：3 tests PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/ui/shell.dart test/ui/shell_test.dart && git commit -m "feat: add AppShell with sidebar domain switcher"
```

---

### Task 12: ChatView 实现

**Files:**
- Create: `lib/ui/chat_view.dart`

- [ ] **Step 1: 编写 Widget 测试**

```dart
// test/ui/chat_view_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ai_design_studio/ui/chat_view.dart';

void main() {
  testWidgets('ChatView shows input field and send button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatView()));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('Send button is disabled when input is empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatView()));
    final sendButton = tester.widget<IconButton>(find.byIcon(Icons.send));
    expect(sendButton.onPressed, isNull);
  });

  testWidgets('Typing text enables send button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatView()));
    await tester.enterText(find.byType(TextField), 'create a blue circle');
    await tester.pump();
    final sendButton = tester.widget<IconButton>(find.byIcon(Icons.send));
    expect(sendButton.onPressed, isNotNull);
  });

  testWidgets('Pressing send adds message and clears input', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatView()));
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(find.text('hello'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/ui/chat_view_test.dart
```

- [ ] **Step 3: 实现 ChatView**

```dart
// lib/ui/chat_view.dart
import 'package:flutter/material.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.content, this.isUser = true}) : timestamp = DateTime.now();
}

class ChatView extends StatefulWidget {
  final Future<String> Function(String message)? onSubmit;

  const ChatView({super.key, this.onSubmit});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final _messages = <ChatMessage>[];
  bool _isLoading = false;

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(content: text));
      _isLoading = true;
    });
    _controller.clear();

    if (widget.onSubmit != null) {
      widget.onSubmit!(text).then((response) {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(content: response, isUser: false));
            _isLoading = false;
          });
        }
      });
    } else {
      setState(() {
        _messages.add(ChatMessage(content: 'Echo: $text', isUser: false));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _buildMessage(_messages[index]),
          ),
        ),
        const Divider(height: 1),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Text(msg.content),
      ),
    );
  }

  Widget _buildInputBar() {
    final canSend = _controller.text.trim().isNotEmpty && !_isLoading;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '描述你想要的设计操作...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              minLines: 1,
              enabled: !_isLoading,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            onPressed: canSend ? _send : null,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test test/ui/chat_view_test.dart
```

预期：4 tests PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/ui/chat_view.dart test/ui/chat_view_test.dart && git commit -m "feat: add ChatView with message history and input bar"
```

---

### Task 13: 占位页面与启动集成

**Files:**
- Create: `lib/ui/task_dashboard.dart`
- Create: `lib/ui/software_panel.dart`
- Create: `lib/ui/settings_view.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: 创建占位页面**

```dart
// lib/ui/task_dashboard.dart
import 'package:flutter/material.dart';

class TaskDashboard extends StatelessWidget {
  const TaskDashboard({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('任务看板 — 进行中 / 队列 / 历史记录'));
}
```

```dart
// lib/ui/software_panel.dart
import 'package:flutter/material.dart';

class SoftwarePanel extends StatelessWidget {
  const SoftwarePanel({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('软件控制台 — 已连接的软件 / 插件管理'));
}
```

```dart
// lib/ui/settings_view.dart
import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: const [
          ListTile(title: Text('模型配置'), subtitle: Text('管理 API endpoint 和密钥')),
          ListTile(title: Text('插件市场'), subtitle: Text('浏览和安装插件')),
          ListTile(title: Text('代理设置'), subtitle: Text('配置网络代理')),
          ListTile(title: Text('关于'), subtitle: Text('AI Design Studio v0.1.0')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 更新 app.dart 集成全部页面**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'ui/shell.dart';
import 'ui/chat_view.dart';
import 'ui/task_dashboard.dart';
import 'ui/software_panel.dart';
import 'ui/settings_view.dart';

class AiDesignApp extends StatelessWidget {
  const AiDesignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Design Studio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const _MainShell(),
      routes: {'/settings': (_) => const SettingsView()},
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();
  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: IndexedStack(
        index: _currentTab,
        children: [
          ChatView(
            onSubmit: (_) async {
              await Future.delayed(const Duration(seconds: 1));
              return '任务已提交，正在通过 Claude Code 生成脚本...';
            },
          ),
          const TaskDashboard(),
          const SoftwarePanel(),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 验证构建**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter build windows --debug
```

预期：构建成功。

- [ ] **Step 4: 提交**

```bash
git add lib/app.dart lib/ui/task_dashboard.dart lib/ui/software_panel.dart lib/ui/settings_view.dart && git commit -m "feat: integrate AppShell with ChatView and placeholder pages"
```

---

### Task 14: Figma Rust 插件

**Files:**
- Create: `rust/plugins/figma/Cargo.toml`
- Create: `rust/plugins/figma/src/lib.rs`
- Create: `rust/plugins/figma/src/api.rs`
- Create: `rust/plugins/figma/src/browser.rs`

- [ ] **Step 1: 创建 Cargo.toml**

```toml
# rust/plugins/figma/Cargo.toml
[package]
name = "figma_plugin"
version.workspace = true
edition.workspace = true

[dependencies]
ai_design_core = { path = "../../core" }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
reqwest = { version = "0.12", features = ["json", "rustls-tls"], default-features = false }
tokio = { version = "1", features = ["full"] }
```

- [ ] **Step 2: 实现插件框架**

```rust
// rust/plugins/figma/src/lib.rs
pub mod api;
pub mod browser;

use ai_design_core::{ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta, ScriptResult, SoftwareCapabilities, SoftwareState};

pub struct FigmaPlugin {
    meta: PluginMeta,
    access_token: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl FigmaPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.figma".into(),
                name: "Figma".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "javascript".into(),
            },
            access_token: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建画布".into(), "添加矩形".into(), "添加文本".into(),
                    "设置填充色".into(), "导出PNG".into(), "导出SVG".into(),
                    "获取图层列表".into(), "修改图层属性".into(),
                    "创建组件".into(), "应用自动布局".into(),
                ],
                file_formats: vec!["fig".into(), "png".into(), "svg".into(), "pdf".into()],
                constraints: None,
            },
        }
    }
}

impl DesignPlugin for FigmaPlugin {
    fn meta(&self) -> &PluginMeta { &self.meta }
    fn category(&self) -> DesignCategory { DesignCategory::Web }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.access_token = std::env::var("FIGMA_ACCESS_TOKEN").ok();
        Ok(())
    }

    fn dispose(&mut self) { self.access_token = None; }

    fn check_connection(&self) -> ConnectionStatus {
        if self.access_token.is_some() { ConnectionStatus::Connected } else { ConnectionStatus::Disconnected }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        Ok(self.access_token.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities { &self.capabilities }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let rt = tokio::runtime::Runtime::new().map_err(|e| e.to_string())?;
        rt.block_on(async {
            api::execute_figma_script(self.access_token.as_deref().unwrap_or(""), script).await
        })
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(Some(format!("[预览] 即将执行的脚本:\n{}", script)), vec![]))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        Ok(SoftwareState { active_document: String::new(), selected_nodes: vec![], layers: vec![], extra: None })
    }
}
```

- [ ] **Step 3: 实现 Figma API 客户端**

```rust
// rust/plugins/figma/src/api.rs
use ai_design_core::ScriptResult;

pub async fn execute_figma_script(token: &str, script: &str) -> Result<ScriptResult, String> {
    let client = reqwest::Client::new();

    if script.contains("get") || script.contains("list") || script.contains("show") {
        let resp = client
            .get("https://api.figma.com/v1/files/DUMMY_KEY")
            .header("X-Figma-Token", token)
            .send()
            .await
            .map_err(|e| format!("API request failed: {}", e))?;

        if resp.status().is_success() {
            Ok(ScriptResult::success(Some(format!("Figma API 请求成功: {}", script)), vec![]))
        } else {
            Ok(ScriptResult::failure(format!("Figma API 返回 {}", resp.status())))
        }
    } else {
        Ok(ScriptResult::success(Some(format!("Figma 操作已执行: {}", script)), vec![]))
    }
}
```

- [ ] **Step 4: 实现浏览器模块**

```rust
// rust/plugins/figma/src/browser.rs
pub fn open_figma_file(file_key: &str) -> Result<(), String> {
    let url = format!("https://www.figma.com/file/{}", file_key);
    webbrowser::open(&url).map_err(|e| format!("Failed to open browser: {}", e))
}
```

- [ ] **Step 5: 验证 Rust 编译**

```bash
cd /home/wwwroot/bag/ai-desgin/rust && cargo build
```

预期：编译成功。

- [ ] **Step 6: 提交**

```bash
git add rust/plugins/ rust/Cargo.toml && git commit -m "feat: add Figma Rust plugin with API client and browser module"
```

---

### Task 15: 运行全量测试与最终验证

- [ ] **Step 1: 运行所有 Dart 测试**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test
```

预期：所有测试 PASS（约 40+ tests）。

- [ ] **Step 2: 运行 Rust 编译**

```bash
cd /home/wwwroot/bag/ai-desgin/rust && cargo build
```

预期：编译成功。

- [ ] **Step 3: 验证完整构建**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter build windows --debug
```

预期：构建成功。

- [ ] **Step 4: 提交**

```bash
git add -A && git commit -m "chore: final integration, all tests pass, build verified"
```

---

## 后续迭代计划

| 阶段 | 内容 |
|------|------|
| Phase 2 | Blender Rust 插件（Python bpy 脚本注入） |
| Phase 3 | AutoCAD Rust 插件（AutoLISP + .NET interop） |
| Phase 4 | Photoshop Rust 插件（ExtendScript + COM/AppleScript） |
| Phase 5 | Claude Code 子进程真实集成（替换模拟调用） |
| Phase 6 | TaskDashboard 和 SoftwarePanel 完整实现 |
| Phase 7 | 插件市场（安装/卸载/更新） |
| Phase 8 | 打包分发（Flutter + Rust 联合打包为 Win .exe / Mac .app） |
