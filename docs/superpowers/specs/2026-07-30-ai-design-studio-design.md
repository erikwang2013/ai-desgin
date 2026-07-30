# AI Design Studio — 设计规格文档

> 状态：已确认（所有设计章节已完成讨论并通过）
> 日期：2026-07-30

## 一、项目概述

一个跨平台（Windows / macOS）桌面应用，封装 Claude Code CLI，通过 AI 驱动多模型调度来生成控制脚本，自动操作各类设计软件。覆盖六大设计领域：Web 设计、广告设计、工业设计、3D 设计、建筑设计、装修设计。

## 二、核心决策

| 决策项 | 选择 | 说明 |
|--------|------|------|
| 桌面框架 | Flutter | 跨 Win/Mac，一致的 UI 体验 |
| Claude Code 集成 | 内置 CLI 调用 | 通过子进程调用 Claude Code，由其编排设计流程 |
| 任务类型 | 控制设计软件 | AI 编写控制脚本，驱动设计软件自动执行操作 |
| 目标用户 | 所有人群 | 既支持自然语言简单交互，也支持专业高级控制 |
| 覆盖策略 | 六个领域同时推进 | 通过插件化架构实现并行开发 |
| 架构模式 | 插件化架构 | 每个设计软件独立插件，共享核心层 |

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
│  │ 任务拆解/排队   │  │ CLI子进程  │  │ deepseek→创意     │  │
│  │ 上下文管理      │  │ 生命周期    │  │ claude→逻辑      │  │
│  │ 会话持久化      │  │ stdio通信  │  │ gemini→视觉      │  │
│  └────────────────┘  └────────────┘  └───────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │              PluginManager (插件管理器)                │    │
│  │  发现 → 加载 → 校验 → 注册 → 生命周期管理              │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────┬───────────────────────────────────────────────┘
               │  Plugin SDK (Dart interface)
               ▼
┌──────────────────────────────────────────────────────────────┐
│                    插件层 (独立包)                             │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │ Figma    │  │ Blender  │  │ AutoCAD  │  │ Photoshop  │  │
│  │ 插件     │  │ 插件     │  │ 插件     │  │ 插件       │  │
│  │          │  │          │  │          │  │            │  │
│  │ REST API │  │ Python   │  │ AutoLISP │  │ ExtendScript│  │
│  │ + 插件API│  │ bpy API  │  │ + .NET   │  │ + UXP     │  │
│  └──────────┘  └──────────┘  └──────────┘  └────────────┘  │
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
                              插件执行 → 设计软件操作
                                          │
                                          ▼
                              结果/截图 ← 用户确认
```

### 关键设计决策

- **上下文管理**：每个设计会话维护独立的上下文窗口，包含当前软件状态、最近操作历史、用户偏好
- **通信方式**：核心层和 Claude Code 之间用 JSON 格式的 stdio 管道通信
- **插件隔离**：插件在独立进程中运行（特别是 Python 脚本插件），主进程只负责任务调度

## 四、插件 SDK 接口设计

每个设计软件插件需要实现的核心接口：

```dart
/// 插件必须实现的核心接口
abstract class DesignPlugin {
  /// 插件元信息
  String get id;            // 唯一标识，如 "com.aidesign.figma"
  String get name;          // 显示名称，如 "Figma"
  String get version;
  DesignCategory get category;  // Web / Ad / Industrial / 3D / Arch / Interior
  String get scriptLanguage;    // 脚本语言：python / javascript / lisp / applescript

  /// 生命周期
  Future<bool> initialize(PluginContext ctx);
  Future<void> dispose();

  /// 连接管理
  Future<ConnectionStatus> checkConnection();    // 检测软件是否运行
  Future<bool> connect(ConnectionConfig config);  // 建立连接

  /// 能力声明 — 告诉 AI 这个软件能做什么
  SoftwareCapabilities get capabilities;

  /// 核心执行
  Future<ScriptResult> execute(String script, {ProgressCallback? onProgress});
  Future<ScriptResult> preview(String script);  // dry-run，不实际执行

  /// 状态获取
  Future<SoftwareState> getCurrentState();  // 当前文档状态快照，用于上下文
}
```

**插件的三个核心职责**：

1. **能力声明** (`capabilities`) — 告诉 Claude Code 这个软件支持什么操作。AI 根据能力声明来生成有效的控制脚本
2. **脚本执行** (`execute`) — 把 AI 生成的脚本注入到目标软件中运行
3. **状态同步** (`getCurrentState`) — 返回当前文档的快照（选中对象、图层列表等），让 AI 知道当前上下文

**插件发现机制**：应用启动 → 扫描插件目录 → 读取 plugin.yaml → 动态加载 → 注入 PluginManager

每个插件是一个独立的 Dart 包，放在 `plugins/` 目录下，包含 `plugin.yaml` 声明文件和实现代码。

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

- 接收用户输入 → 构建上下文包（软件状态 + 能力声明 + 会话历史 + 用户偏好）→ 提交给 CCProcessManager → Claude Code 生成脚本 → PluginManager 执行 → 收集结果 → 更新会话上下文 → 返回用户
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
