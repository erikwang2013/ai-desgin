# AI Design Studio — 设计规格文档

> 状态：已确认并持续迭代（22 个软件插件，含 CAD/BIM/切片器/AI 生成）
> 日期：2026-07-30 · 更新：2026-08-01（第四次更新）

## 当前构建状态 (2026-08-01)

| 检查项 | 状态 |
|--------|------|
| `dart analyze lib/` | No issues found |
| `flutter test` | 47/49 passed（2 超时与 CLI 相关） |
| `cargo check` | 22 crates, 0 warnings |
| `cargo clippy` | 0 warnings |
| 版本 | 全局统一 1.0.6（`lib/core/version.dart`） |

详见：[审查报告 v1](../../review-report-2026-07-31.md) | [审查报告 v2](../../review-report-2026-08-01.md) | [测试报告](../../test-report-2026-07-31.md)

## 一、项目概述

一个跨平台（Windows / macOS）桌面应用，封装 Claude Code CLI，通过 AI 驱动多模型调度来生成控制脚本，自动操作各类设计软件。覆盖六大设计领域：Web 设计、广告设计、工业设计、3D 设计、建筑设计、装修设计。

## 二、核心决策

| 决策项 | 选择 | 说明 |
|--------|------|------|
| 桌面框架 | Flutter | 跨 Win/Mac，一致的 UI 体验 |
| 插件实现语言 | Rust | 系统级 API 调用、原生 IPC、独立进程隔离 |
| Claude Code 集成 | 内置 CLI 调用 | 通过子进程调用 Claude Code，由其编排设计流程 |
| 任务类型 | 控制设计软件 | AI 编写控制脚本，驱动设计软件自动执行操作 |
| 目标用户 | 所有人群 | 既支持自然语言简单交互，也支持专业高级控制 |
| 覆盖策略 | 六个领域同时推进 | 通过插件化架构实现并行开发 |
| 架构模式 | 插件化架构 | Dart 接口定义 + Rust crate 实现，flutter_rust_bridge 桥接 |

## 三、整体架构

### 三层架构

```
┌──────────────────────────────────────────────────────────────┐
│                    用户层 (Flutter UI)                        │
│                                                              │
│  对话面板              任务看板              软件控制台       │
│  "帮我把这个Figma       │ 进行中 / 队列 /     │ 已连接的软件   │
│   页面转成HTML"          │ 历史记录            │ 插件管理      │
└──────────────┬────────────────────────────────┬──────────────┘
               │                                │
               ▼                                ▼
┌──────────────────────────────────────────────────────────────┐
│                    核心层 (Dart)                              │
│                                                              │
│  ┌────────────────┐  ┌────────────┐  ┌───────────────────┐  │
│  │ TaskOrchestra- │  │ CCProcess  │  │ ModelRouter       │  │
│  │ tor            │  │ Manager    │  │                   │  │
│  │ 任务拆解/排队   │  │ CLI子进程  │  │ 按任务类型自动    │  │
│  │ 上下文管理      │  │ 生命周期    │  │ 选择最优模型      │  │
│  │ 会话持久化      │  │ stdio通信  │  │                   │  │
│  └────────────────┘  └────────────┘  └───────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              PluginManager (插件管理器)                │    │
│  │  发现 → 加载 → 校验 → 注册 → 生命周期管理              │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────┬───────────────────────────────────────────────┘
               │  flutter_rust_bridge / dart:ffi
               ▼
┌──────────────────────────────────────────────────────────────┐
│                    插件层 (Rust crates)                       │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │ Figma    │  │ Blender  │  │ AutoCAD  │  │ Photoshop  │  │
│  │ crate    │  │ crate    │  │ crate    │  │ crate      │  │
│  │          │  │          │  │          │  │            │  │
│  │ REST API │  │ Python   │  │ AutoLISP │  │ ExtendScript│  │
│  │ + 浏览器 │  │ bpy 注入 │  │ + .NET   │  │ + COM/     │  │
│  │ 自动化   │  │          │  │ interop  │  │ AppleScript│  │
│  └──────────┘  └──────────┘  └──────────┘  └────────────┘  │
│                                                              │
│  Rust 选型理由：系统级 API、原生 IPC、独立进程隔离、         │
│  .dll/.dylib 产物，flutter_rust_bridge 自动生成 FFI 绑定    │
└──────────────────────────────────────────────────────────────┘
```

### 一次任务的数据流

```
用户输入 → TaskOrchestrator → CCProcessManager → Claude Code CLI
                                                      │
                                          ┌───────────┘
                                          ▼
                                   模型路由决策 + 脚本生成
                                          │
                                          ▼
                              生成的脚本 ← PluginManager
                                          │
                                          ▼
                     Rust crate 执行 → 设计软件操作
                                          │
                                          ▼
                              结果/截图 ← 用户确认
```

### 关键设计决策

- **上下文管理**：每个设计会话维护独立的上下文窗口，包含当前软件状态、最近操作历史、用户偏好
- **通信方式**：核心层和 Claude Code 之间用 JSON 格式的 stdio 管道通信
- **Dart ↔ Rust 桥接**：通过 flutter_rust_bridge 自动生成 FFI 绑定，Dart 调用 Rust 如同调用本地方法
- **插件隔离**：每个 Rust crate 在独立进程中运行，主进程只负责任务调度

## 四、插件 SDK 接口设计

插件采用 **Dart 定义接口 + Rust 实现** 的分层模式。Dart 侧通过 flutter_rust_bridge 调用 Rust 原生代码。

**Dart 侧 — 接口定义（供 UI 和核心层使用）**：

```dart
abstract class DesignPlugin {
  String get id;
  String get name;
  String get version;
  DesignCategory get category;
  Future<bool> initialize(PluginContext ctx);
  Future<void> dispose();
  Future<ConnectionStatus> checkConnection();
  Future<bool> connect(ConnectionConfig config);
  SoftwareCapabilities get capabilities;
  Future<ScriptResult> execute(String script, {ProgressCallback? onProgress});
  Future<ScriptResult> preview(String script);
  Future<SoftwareState> getCurrentState();
}
```

**Rust 侧 — 实际执行（每个设计软件一个 crate）**：

```rust
pub trait DesignPlugin: Send + Sync {
    fn id(&self) -> &str;
    fn name(&self) -> &str;
    fn initialize(&mut self, ctx: &PluginContext) -> Result<bool>;
    fn check_connection(&self) -> Result<ConnectionStatus>;
    fn capabilities(&self) -> &SoftwareCapabilities;

    /// 执行脚本 — 系统级操作就发生在这里
    fn execute(&self, script: &str, on_progress: Option<Box<dyn Fn(f64)>>) -> Result<ScriptResult>;
    fn preview(&self, script: &str) -> Result<ScriptResult>;
    fn get_current_state(&self) -> Result<SoftwareState>;
}

// 每个软件是独立的 crate
// crates/figma_plugin/   → REST API + 浏览器自动化
// crates/blender_plugin/ → Python bpy 脚本注入
// crates/autocad_plugin/ → AutoLISP + .NET interop
// crates/ps_plugin/      → ExtendScript + COM(Win) / AppleScript(Mac)
```

**Rust 插件层的优势**：

| 能力 | Rust 实现方式 |
|------|-------------|
| 系统 API 调用 | FFI 直调 Win32 COM / macOS NSAppleScript |
| 进程管理 | `std::process::Command` 启动/监控设计软件 |
| 脚本注入 | 原生管道通信、AppleEvent、OLE Automation |
| 编译产物 | 各 crate 编译为 .dll / .dylib，打包到应用内 |
| 崩溃隔离 | 每个插件在独立隔离进程运行 |
| 跨平台 | `#[cfg(target_os)]` 条件编译，同一 crate 适配 Win/Mac |

**通信链路**：

```
Dart UI → flutter_rust_bridge → Rust crate → 设计软件
```

flutter_rust_bridge 自动从 Rust 代码生成 Dart 绑定，Dart 调用 Rust 方法就像调用普通 Dart 对象。

## 五、Claude Code 进程管理

**进程生命周期**：
- 每个活跃会话对应一个 Claude Code 子进程
- 空闲超过 5 分钟自动回收
- 最多同时运行 3 个进程（可配置），超出排队
- 进程崩溃时自动重启，恢复上下文

**通信协议** — 核心层和 Claude Code 子进程之间用 JSON-RPC over stdio：

```json
// → 发送给 Claude Code
{
  "id": "msg_001",
  "method": "design.execute",
  "params": {
    "sessionId": "sess_abc",
    "software": "figma",
    "capabilities": { "actions": ["创建矩形","设置填充色"...], "state": {...} },
    "task": "把画布上所有蓝色矩形改成红色",
    "model": "claude-sonnet-4-6"
  }
}

// ← Claude Code 返回
{
  "id": "msg_001",
  "result": {
    "script": "for node in figma.currentPage.selection...",
    "scriptLanguage": "javascript",
    "explanation": "遍历当前页面选中节点，匹配填充色为蓝色的矩形并修改",
    "estimatedDuration": "2s",
    "modelUsed": "claude-sonnet-4-6"
  }
}
```

## 六、模型路由策略

| 任务类型 | 推荐模型 | 示例 |
|---------|---------|------|
| UI/视觉设计（高精度视觉） | Claude Opus | Figma 页面布局、配色方案 |
| 逻辑/代码生成（大量脚本输出） | Claude Sonnet | 网页 HTML/CSS 生成、插件脚本编写 |
| 3D/空间推理 | 视觉模型（可配置） | Blender 场景搭建、CAD 参数化建模 |
| 快速/简单操作 | Claude Haiku | 批量重命名图层、导出设置 |
| 创意/头脑风暴 | 创意模型（可配置） | 广告文案+设计方向、装修风格建议 |

路由规则定义在 `config/model-routing.yaml`，用户可自定义。支持替换为其他兼容 API 的模型（Gemini、DeepSeek 等），只需配置 endpoint 和 API key。

## 七、Flutter UI 结构

四个核心页面（Flutter 路由）：

| 页面 | 功能 |
|------|------|
| `ChatView` | 主对话界面，自然语言交互，内嵌脚本预览和执行结果 |
| `TaskDashboard` | 任务队列、历史记录、当前进度 |
| `SoftwarePanel` | 已连接软件状态、插件管理、一键启动软件 |
| `SettingsView` | 模型配置、API key、代理设置、插件市场 |

布局采用经典侧边栏+主内容区结构，对话组件、脚本预览组件、进度组件在多个页面共用。

## 八、任务编排器（TaskOrchestrator）

- 接收用户输入 → 构建上下文包（软件状态 + 能力声明 + 会话历史 + 用户偏好）→ 提交给 CCProcessManager → Claude Code 生成脚本 → PluginManager → Rust crate 执行 → 收集结果 → 更新会话上下文 → 返回用户
- 支持最多 3 个并发任务，超出排队
- 支持任务链：A 的输出作为 B 的输入
- 每个任务有独立 `taskId`，可取消、可重试

## 九、会话与持久化

```dart
class Session {
  final String id;
  final DesignCategory domain;     // 当前设计领域
  final String softwareName;       // 如 "Figma"
  final List<TaskRecord> history;  // 任务历史
  final SessionContext context;    // 软件状态快照 + 用户偏好
  final DateTime createdAt;
}
```

持久化到本地 SQLite。支持会话恢复、历史搜索、跨软件上下文传递。

## 十、安全与沙箱

- 插件在独立进程中执行脚本，通过进程隔离防止崩溃扩散
- 脚本执行前进行静态安全检查（禁止文件系统越权、网络越权）
- 用户可预览脚本后再执行（preview 模式）
- 敏感操作（删除、覆盖文件）需要用户二次确认
- API key 存储在系统本地加密存储（macOS Keychain / Windows Credential Manager）

## 十一、设计软件插件扩展（2026-07-31 更新）

### 新增插件

在原有 4 个设计软件插件基础上，陆续扩展至 21 个软件，覆盖完整的设计与制造工作流：

**平面/UI 设计**：Figma、Photoshop、Illustrator、Sketch
**CAD/BIM 建模**：Fusion 360、SolidWorks、FreeCAD、OpenSCAD、Rhino、Blender、AutoCAD、Revit、SketchUp
**Web/AI**：Tinkercad、Meshy
**FDM 切片**：Cura、PrusaSlicer、OrcaSlicer、Simplify3D
**树脂切片**：ChiTuBox、Lychee Slicer

### 控制方式分类

| 方式 | 软件 |
|------|------|
| Python API | Fusion 360、FreeCAD、Rhino、Blender、Revit (Dynamo) |
| CLI | Cura、PrusaSlicer、OrcaSlicer、Simplify3D、ChiTuBox、Lychee |
| REST API | Figma、Tinkercad、Meshy |
| VBA/COM | SolidWorks |
| SCAD 脚本 | OpenSCAD |
| AutoLISP | AutoCAD |
| ExtendScript | Photoshop、Illustrator |
| Ruby API | SketchUp |
| sketchtool/JS | Sketch |
| .NET API | Revit |

### 典型 3D 打印工作流

```
用户: "把这个 STL 模型用 PrusaSlicer 切片，层高 0.2mm，填充 20%"
  ↓
Claude Code → 选择 Sonnet → 生成 PrusaSlicer CLI 命令
  ↓
Rust 插件写配置 → 调用 prusa-slicer CLI → 生成 GCode → 返回结果
```
