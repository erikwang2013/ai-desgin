# AI Design

> 跨平台 AI 驱动设计工具 — 封装 Claude Code，调用多模型智能控制各类设计软件

[English](README_EN.md)

## 项目简介

AI Design是一个支持 **Windows** 和 **macOS** 的桌面应用，通过内置 Claude Code CLI 实现 AI 驱动的多模型调度，自动生成控制脚本并操作各类设计软件。覆盖 **六大设计领域**：Web 设计、广告设计、工业设计、3D 设计、建筑设计、装修设计。

### 核心理念

设计师不需要学习每种软件的脚本语言。用自然语言描述需求，AI 自动生成并执行控制脚本，直接操作设计软件完成重复性工作。

```
用户: "把画布上所有蓝色矩形改成红色"
  ↓
Claude Code 分析任务 → 选择最优模型 → 生成 Figma JavaScript 脚本
  ↓
Rust 插件注入脚本 → Figma 执行 → 返回结果
```

## 架构设计

### 三层架构

```
┌──────────────────────────────────────────┐
│  Flutter UI (Dart)                       │
│  ChatView · TaskDashboard · SoftwarePanel│
├──────────────────────────────────────────┤
│  核心层 (Dart)                            │
│  TaskOrchestrator · CCProcessManager     │
│  ModelRouter · PluginManager · Session   │
├──────────────────────────────────────────┤
│  插件层 (Rust crates)                     │
│  Figma · Blender · AutoCAD · Photoshop   │
│  (通过 flutter_rust_bridge FFI 桥接)      │
└──────────────────────────────────────────┘
```

### 技术栈

| 层 | 技术 | 用途 |
|---|------|------|
| UI | Flutter 3.x + Material 3 | 跨平台桌面界面 |
| 核心逻辑 | Dart | 任务编排、模型路由、会话管理 |
| 插件 | Rust | 系统级 API 调用、进程管理、脚本注入 |
| 桥接 | flutter_rust_bridge | Dart ↔ Rust FFI 自动生成 |
| AI 引擎 | Claude Code CLI | 多模型调度与脚本生成 |
| 持久化 | SQLite (sqflite) | 会话与任务历史 |

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

### 插件架构

每个设计软件作为独立 Rust crate，实现统一的 `DesignPlugin` trait：

```
Dart (接口定义)  →  flutter_rust_bridge  →  Rust (真实执行)
                                                 │
                  ┌──────────────────────────────┼──────────────────────────┐
                  ▼                              ▼                          ▼
            figma_plugin                  blender_plugin              autocad_plugin
            (REST API)                    (Python bpy)                (AutoLISP)
```

### 模型路由

| 任务类型 | 模型 | 示例 |
|---------|------|------|
| UI/视觉设计 | Claude Opus | Figma 布局、配色方案 |
| 逻辑/代码生成 | Claude Sonnet | HTML/CSS、插件脚本 |
| 3D/空间推理 | 视觉模型 | Blender 建模、CAD 参数化 |
| 简单操作 | Claude Haiku | 批量重命名、导出设置 |
| 创意构思 | 创意模型 | 广告方案、风格建议 |

路由规则通过 `config/model-routing.yaml` 配置，支持接入任何兼容 OpenAI API 格式的模型。

## 项目结构

```
ai-desgin/
├── lib/
│   ├── main.dart                          # 应用入口
│   ├── app.dart                           # MaterialApp + 路由
│   ├── models/                            # 数据模型
│   │   ├── session.dart                   # Session, DesignCategory
│   │   ├── task_record.dart               # TaskRecord, TaskStatus
│   │   ├── plugin.dart                    # PluginMeta, ScriptResult
│   │   └── software_capabilities.dart     # SoftwareCapabilities
│   ├── plugin_sdk/
│   │   └── design_plugin.dart             # DesignPlugin 抽象接口
│   ├── core/
│   │   ├── plugin_manager.dart            # 插件注册/生命周期
│   │   ├── model_router.dart              # 模型路由引擎
│   │   ├── cc_process_manager.dart        # Claude Code 会话管理
│   │   ├── cc_runner.dart                 # Claude Code 子进程通信
│   │   ├── task_orchestrator.dart         # 任务编排引擎
│   │   └── session_store.dart             # SQLite 会话持久化
│   └── ui/
│       ├── shell.dart                     # 侧边栏 + 页面布局
│       ├── chat_view.dart                 # AI 对话面板
│       ├── task_dashboard.dart            # 任务队列/历史
│       ├── software_panel.dart            # 软件连接/状态
│       ├── settings_view.dart             # 系统设置
│       └── plugin_marketplace.dart        # 插件市场
├── rust/
│   ├── Cargo.toml                         # Rust workspace 根
│   ├── core/
│   │   └── src/
│   │       ├── traits.rs                  # DesignPlugin Rust trait
│   │       ├── types.rs                   # 共享类型定义
│   │       └── ipc.rs                     # 进程隔离工具
│   └── plugins/
│       ├── figma/                         # Figma 插件 (REST API)
│       ├── photoshop/                     # Photoshop 插件 (ExtendScript)
│       ├── blender/                       # Blender 插件 (Python)
│       ├── fusion360/                     # Fusion 360 插件 (Python)
│       ├── solidworks/                    # SolidWorks 插件 (VBA/COM)
│       ├── freecad/                       # FreeCAD 插件 (Python)
│       ├── openscad/                      # OpenSCAD 插件 (SCAD)
│       ├── rhino/                         # Rhino 插件 (Python)
│       ├── autocad/                       # AutoCAD 插件 (AutoLISP)
│       ├── tinkercad/                     # Tinkercad 插件 (REST)
│       ├── meshy/                         # Meshy 插件 (AI REST)
│       ├── cura/                          # Cura 插件 (CLI)
│       ├── prusaslicer/                   # PrusaSlicer 插件 (CLI)
│       ├── orcaslicer/                    # OrcaSlicer 插件 (CLI)
│       ├── simplify3d/                    # Simplify3D 插件 (CLI)
│       ├── chitubox/                      # ChiTuBox 插件 (CLI)
│       └── lychee/                        # Lychee 插件 (CLI)
├── config/
│   └── model-routing.yaml                 # 模型路由配置
├── scripts/
│   ├── build.sh                           # Unix 构建脚本
│   ├── build_windows.bat                  # Windows 构建脚本
│   └── release.sh                         # 发布打包脚本
├── test/                                  # Dart 测试 (49 tests)
├── docs/
│   └── superpowers/
│       ├── specs/                         # 设计规格文档
│       └── plans/                         # 实现计划文档
├── pubspec.yaml                           # Flutter 依赖声明
└── flutter_rust_bridge.yaml               # Rust 桥接配置
```

## 快速开始

### 环境要求

- **Flutter SDK** ≥ 3.x（含 Windows/macOS 平台支持）
- **Rust** ≥ 1.75（Cargo + rustup）
- **Claude Code CLI**（可选，用于 AI 脚本生成功能）
- 至少一款设计软件：Figma / Blender / AutoCAD / Photoshop

### 安装与构建

```bash
# 克隆项目
git clone <repo-url> ai-desgin
cd ai-desgin

# 安装 Flutter 依赖
flutter pub get

# 编译 Rust 插件
cd rust && cargo build --release && cd ..

# 一键构建
bash scripts/build.sh        # macOS / Linux
scripts\build_windows.bat     # Windows

# 开发模式
flutter run -d windows        # 或 -d macos
```

### 运行测试

```bash
flutter test                  # 全部 Dart 测试
cd rust && cargo build        # Rust 编译验证
```

## 使用教程

### 第一步：连接软件

打开应用，在左侧「软件控制台」查看已安装的插件。状态灯显示连接情况：绿色已连接、灰色未连接。确保目标设计软件已启动。

### 第二步：选择领域

左侧边栏切换设计领域，AI 会根据领域自动选择合适的模型和控制策略：
- **Web 设计** → Figma、Sketch
- **广告设计** → Photoshop、Illustrator
- **工业设计** → Fusion 360、SolidWorks
- **3D 设计** → Blender、Maya
- **建筑设计** → AutoCAD、Revit
- **装修设计** → SketchUp、3ds Max

### 第三步：描述需求

在对话面板用自然语言描述设计操作：

> 「在 Figma 中创建 1440x900 的登录页面，居中白色卡片，包含邮箱输入框、密码框和蓝色登录按钮」

> 「在 Blender 中创建一个房间场景，添加地板材质和点光源」

> 「把当前 Photoshop 文档中所有文字图层的字体改为思源黑体」

### 第四步：预览执行

AI 生成脚本后会展示预览，确认无误后点击执行。执行结果实时显示在对话框中。

### 第五步：管理任务

在「任务看板」追踪所有任务状态：等待中 / 进行中 / 已完成 / 失败。可按状态筛选，查看历史记录。

### 配置模型

在「设置 → 模型配置」中配置 API endpoint 和密钥。模型路由规则在 `config/model-routing.yaml` 中自定义。

### 安装新插件

「设置 → 插件市场」中浏览可用插件，一键安装。安装后即可在软件控制台中看到新的软件入口。

## 功能说明

### 平面与 UI 设计

支持 Figma 和 Photoshop 的自动化操作。AI 可以创建画布、添加图层、设置样式、导出切图，将设计稿直接转为 HTML/CSS 代码。

### 3D 建模与 CAD

覆盖主流参数化建模、多边形建模和 NURBS 曲面建模软件。AI 可自动创建零件、装配体、生成工程图、导出 STL/STEP 等格式用于 3D 打印。

### 3D 打印切片

完整支持 FDM 和树脂打印流程。AI 可根据模型复杂度自动设置层高、填充密度、支撑结构，一键生成 GCode 或 CTB 切片文件。

### AI 模型生成

通过 Meshy API 实现文字/图片到 3D 模型的 AI 生成，自动优化面数、生成纹理、导出多格式。

## 已支持的软件

### 平面设计（4 个）

| 软件 | 控制方式 | 平台 | 状态 |
|------|---------|------|------|
| Figma | REST API + 浏览器自动化 | Web/macOS/Win | ✅ |
| Photoshop | ExtendScript + COM/AppleScript | macOS/Win | ✅ |
| Sketch | AppleScript | macOS | ⏳ |
| Illustrator | ExtendScript | macOS/Win | ⏳ |

### CAD 建模（7 个）

| 软件 | 控制方式 | 平台 | 状态 |
|------|---------|------|------|
| Fusion 360 | Python API | macOS/Win | ✅ |
| SolidWorks | VBA/COM | Win | ✅ |
| FreeCAD | Python API | macOS/Win/Linux | ✅ |
| OpenSCAD | SCAD 脚本 | macOS/Win/Linux | ✅ |
| Rhino | Python/RhinoScript | macOS/Win | ✅ |
| Blender | Python bpy | macOS/Win/Linux | ✅ |
| AutoCAD | AutoLISP | macOS/Win | ✅ |

### FDM 切片器（4 个）

| 软件 | 控制方式 | 平台 | 状态 |
|------|---------|------|------|
| UltiMaker Cura | CuraEngine CLI | macOS/Win/Linux | ✅ |
| PrusaSlicer | CLI | macOS/Win/Linux | ✅ |
| OrcaSlicer | CLI | macOS/Win/Linux | ✅ |
| Simplify3D | CLI | macOS/Win | ✅ |

### 树脂切片器（2 个）

| 软件 | 控制方式 | 平台 | 状态 |
|------|---------|------|------|
| ChiTuBox | CLI | macOS/Win | ✅ |
| Lychee Slicer | CLI | macOS/Win/Linux | ✅ |

### Web / AI（2 个）

| 软件 | 控制方式 | 平台 | 状态 |
|------|---------|------|------|
| Tinkercad | REST API | Web | ✅ |
| Meshy | REST API（AI 生成） | Web | ✅ |

### 计划中

| 软件 | 控制方式 | 平台 |
|------|---------|------|
| Revit | .NET API | Win |
| SketchUp | Ruby API | macOS/Win |

## 开发指南

### 添加新插件

1. 在 `rust/plugins/` 下创建新 Rust crate
2. 实现 `DesignPlugin` trait（参考 `rust/core/src/traits.rs`）
3. 在 `rust/Cargo.toml` workspace members 中添加新 crate
4. Dart 侧通过 `flutter_rust_bridge` 生成绑定

详见设计文档：[设计规格](docs/superpowers/specs/2026-07-30-ai-design-studio-design.md) | [实现计划](docs/superpowers/plans/2026-07-30-ai-design-studio-plan.md)

### 配置说明

**模型路由** (`config/model-routing.yaml`)：

```yaml
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

**环境变量**：

| 变量 | 说明 |
|------|------|
| `FIGMA_ACCESS_TOKEN` | Figma Personal Access Token |
| `MESHY_API_KEY` | Meshy AI 3D 模型生成 API 密钥 |
| `TINKERCAD_ACCESS_TOKEN` | Tinkercad API 访问令牌 |

## 许可证

MIT
