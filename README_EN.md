# AI Design

> Cross-platform AI-powered design automation — Claude Code integration with multi-model orchestration for controlling design software

[中文](README.md)

## Overview

AI Design is a **Windows** and **macOS** desktop application that wraps Claude Code CLI to enable AI-driven multi-model orchestration. It automatically generates and executes control scripts for various design software across **six design domains**: Web, Advertising, Industrial, 3D, Architecture, and Interior Design.

### Core Idea

Designers shouldn't need to learn every software's scripting language. Describe what you want in natural language, and AI generates and executes the control scripts to automate repetitive design tasks.

```
User: "Change all blue rectangles on the canvas to red"
  ↓
Claude Code analyzes task → selects optimal model → generates Figma JS script
  ↓
Rust plugin injects script → Figma executes → returns result
```

## Architecture

### Three-Layer Design

```
+------------------------------------------+
|  Flutter UI (Dart)                       |
|  ChatView · TaskDashboard · SoftwarePanel|
+------------------------------------------+
|  Core Layer (Dart)                        |
|  TaskOrchestrator · CCProcessManager     |
|  ModelRouter · PluginManager · Session   |
+------------------------------------------+
|  Plugin Layer (Rust crates)               |
|  Figma · Blender · AutoCAD · Photoshop   |
|  (bridged via flutter_rust_bridge FFI)    |
+------------------------------------------+
```

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| UI | Flutter 3.x + Material 3 | Cross-platform desktop UI |
| Core Logic | Dart | Task orchestration, model routing, session management |
| Plugins | Rust | System-level API calls, process management, script injection |
| Bridge | flutter_rust_bridge | Auto-generated Dart-Rust FFI bindings |
| AI Engine | Claude Code CLI | Multi-model orchestration and script generation |
| Storage | SQLite (sqflite) | Session and task history persistence |

### Data Flow

```
User Input → TaskOrchestrator → CCProcessManager → Claude Code CLI
                                                       |
                                           +-----------+
                                           v
                                   Model routing + script generation
                                           |
                                           v
                              Generated script <- PluginManager
                                           |
                                           v
                       Rust crate executes → Design software operation
                                           |
                                           v
                              Result/screenshot <- User confirmation
```

### Plugin Architecture

Each design software is an independent Rust crate implementing the `DesignPlugin` trait:

```
Dart (interface)  →  flutter_rust_bridge  →  Rust (execution)
                                                   |
                    +------------------------------+--------------------------+
                    v                              v                          v
              figma_plugin                  blender_plugin              autocad_plugin
              (REST API)                    (Python bpy)                (AutoLISP)
```

### Model Routing

| Task Type | Model | Example |
|-----------|-------|---------|
| UI/Visual Design | Claude Opus | Figma layout, color schemes |
| Logic/Code Generation | Claude Sonnet | HTML/CSS, plugin scripts |
| 3D/Spatial Reasoning | Visual model | Blender modeling, CAD |
| Simple Operations | Claude Haiku | Batch rename, export |
| Creative Brainstorming | Creative model | Ad copy, style suggestions |

Routing rules are configured in `config/model-routing.yaml`. Any OpenAI-compatible API model can be plugged in.

## Project Structure

```
ai-desgin/
+-- lib/
|   +-- main.dart                          # App entry point
|   +-- app.dart                           # MaterialApp + routing
|   +-- models/                            # Data models
|   +-- plugin_sdk/                        # Plugin interface
|   +-- core/                              # Core managers
|   |   +-- plugin_manager.dart            # Plugin registry
|   |   +-- model_router.dart              # Model routing engine
|   |   +-- cc_process_manager.dart        # Claude Code session mgmt
|   |   +-- cc_runner.dart                 # Claude Code subprocess
|   |   +-- task_orchestrator.dart         # Task orchestration
|   |   +-- session_store.dart             # SQLite persistence
|   |   +-- builtin_plugins.dart             # Built-in plugin registry (single source of truth)
|   +-- ui/                                # UI pages
+-- rust/
|   +-- core/                              # Shared traits + types
|   +-- plugins/                           # 39 software plugins
|       +-- figma/                         # Figma (REST API)
|       +-- photoshop/                     # Photoshop (ExtendScript)
|       +-- illustrator/                   # Illustrator (ExtendScript)
|       +-- indesign/                      # InDesign (ExtendScript)
|       +-- sketch/                        # Sketch (sketchtool/JS)
|       +-- blender/                       # Blender (Python)
|       +-- maya/                          # Maya (Python)
|       +-- 3dsmax/                        # 3ds Max (MaxScript/Python)
|       +-- cinema4d/                      # Cinema 4D (Python)
|       +-- fusion360/                     # Fusion 360 (Python)
|       +-- solidworks/                    # SolidWorks (VBA/COM)
|       +-- freecad/                       # FreeCAD (Python)
|       +-- openscad/                      # OpenSCAD (SCAD)
|       +-- rhino/                         # Rhino (Python)
|       +-- zw3d/                          # ZW3D (Python)
|       +-- autocad/                       # AutoCAD (AutoLISP)
|       +-- revit/                         # Revit (Dynamo/.NET)
|       +-- sketchup/                      # SketchUp (Ruby)
|       +-- tinkercad/                     # Tinkercad (REST)
|       +-- meshy/                         # Meshy (AI REST)
|       +-- 3done/                         # 3D One (Python)
|       +-- voxeldance/                    # VoxelDance Additive
|       +-- happy3d/                       # Happy3D (Python)
|       +-- maodou3d/                      # Maodou 3D (Python)
|       +-- cura/                          # Cura (CLI)
|       +-- prusaslicer/                   # PrusaSlicer (CLI)
|       +-- orcaslicer/                    # OrcaSlicer (CLI)
|       +-- simplify3d/                    # Simplify3D (CLI)
|       +-- chitubox/                      # ChiTuBox (CLI)
|       +-- lychee/                        # Lychee (CLI)
|       +-- makerlab/                      # MakerLab (Python)
|       +-- crealitycloud/                 # Creality Cloud (Python)
|       +-- flashprint/                    # FlashPrint (Python)
|       +-- flashstudio/                   # Flash Studio (Python)
|       +-- snapmakerluban/                # Snapmaker Luban (Python)
|       +-- snapmakerorca/                 # Snapmaker Orca (Python)
|       +-- buildplanner/                  # Build Planner (Python)
|       +-- flashdental/                   # FlashDental (Python)
|       +-- waxjetprint/                   # WaxJetPrint (Python)
+-- config/model-routing.yaml
+-- scripts/                               # Build + release scripts
+-- test/                                  # Dart tests
+-- docs/
    +-- test-report-2026-07-31.md          # Test report
    +-- review-report-2026-07-31.md        # Code review
    +-- review-report-2026-07-31-v2.md     # Code review v2
    +-- superpowers/                       # Design specs + plans
```

## Quick Start

### Prerequisites

- **Flutter SDK** >= 3.x (with Windows/macOS build support)
- **Rust** >= 1.75 (Cargo + rustup)
- **Claude Code CLI** (optional, for AI script generation)
- At least one design software: Figma / Blender / AutoCAD / Photoshop

### Setup

```bash
# Clone
git clone <repo-url> ai-desgin && cd ai-desgin

# Install dependencies
flutter pub get
cd rust && cargo build --release && cd ..

# Build
bash scripts/build.sh            # macOS / Linux
scripts\build_windows.bat         # Windows

# Dev mode
flutter run -d windows            # or -d macos
```

### Tests

```bash
flutter test                      # All Dart tests
cd rust && cargo build            # Rust compilation (40 crates)
cd rust && cargo clippy           # Rust lint check
```

### Code Quality

| Check | Status |
|-------|--------|
| `flutter analyze` | No issues found |
| `flutter test` | All passing |
| `cargo build` | 40 crates compiled |
| `cargo clippy` | 0 warnings |

Detailed reports: [Review v3](docs/review-report-2026-07-31-v3.md) | [Review v2](docs/review-report-2026-07-31-v2.md) | [Test](docs/test-report-2026-07-31.md)

## Usage

### 1. Connect Software

Open the app and check installed plugins in the Software Panel. Green indicator = connected, gray = not connected. Make sure your design software is running.

### 2. Select Domain

Choose a design domain from the sidebar. The AI will automatically select the optimal model and strategy:
- **Web** -> Figma, Sketch
- **Advertising** -> Photoshop, Illustrator, InDesign
- **Industrial** -> Fusion 360, SolidWorks, ZW3D, VoxelDance Additive
- **3D** -> Blender, Maya, 3ds Max, Cinema 4D, 3D One, Happy3D, Maodou 3D
- **Architecture** -> AutoCAD, Revit
- **Interior** -> SketchUp

### 3. Describe Your Task

Type design instructions in natural language:

> "Create a 1440x900 login page in Figma with a centered white card, email input, password field, and blue login button"

> "Set up a room scene in Blender with a floor material and a point light"

> "Change all text layers in the current Photoshop document to use Source Han Sans"

### 4. Preview & Execute

AI generates a script preview before execution. Review it, then confirm to run. Results appear inline in the chat.

### 5. Manage Tasks

Track all tasks in the Task Dashboard: pending / running / completed / failed. Filter by status and browse history.

### Configure Models

Set up API endpoints and keys in Settings -> Model Configuration. Customize routing rules in `config/model-routing.yaml`.

### Install Plugins

Browse available plugins in Settings -> Plugin Marketplace. One-click install. New software entries appear in the Software Panel immediately.

## Features

### Graphic & UI Design

Automate Figma, Sketch, Photoshop, Illustrator and InDesign operations. AI can create canvases, add layers, apply styles, export assets, and convert designs directly to HTML/CSS code.

### 3D Modeling & Animation

Covering parametric, polygonal, and NURBS surface modeling. Supports Maya, 3ds Max, and Cinema 4D for rigging, animation, and rendering. AI can auto-create parts, assemblies, generate technical drawings, and export STL/STEP formats for 3D printing.

### 3D Print Slicing & Management

Full support for FDM and resin printing workflows across major slicers and print management platforms. AI automatically configures layer height, infill density, and support structures based on model complexity. Supports Snapmaker multi-function CAM, Creality Cloud remote printing, and FlashDental dental printing workflows.

### AI Model Generation

Text-to-3D and image-to-3D generation via Meshy API, with automatic polygon optimization, texture generation, and multi-format export.

## Supported Software

### Graphic & UI Design (5)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| Figma | REST API | Web/macOS/Win | Supported |
| Photoshop | ExtendScript + COM/AppleScript | macOS/Win | Supported |
| Sketch | sketchtool CLI + osascript | macOS | Supported |
| Illustrator | ExtendScript | macOS/Win | Supported |
| InDesign | ExtendScript | macOS/Win | Supported |

### 3D Animation & Modeling (7)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| Blender | Python bpy | macOS/Win/Linux | Supported |
| Maya | Python API | macOS/Win/Linux | Supported |
| 3ds Max | MaxScript / Python | Win | Supported |
| Cinema 4D | Python API | macOS/Win | Supported |
| SketchUp | Ruby API | macOS/Win | Supported |
| Rhino | Python/RhinoScript | macOS/Win | Supported |
| Meshy | REST API (AI Generation) | Web | Supported |

### CAD & BIM Modeling (6)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| Fusion 360 | Python API | macOS/Win | Supported |
| SolidWorks | VBA/COM | Win | Supported |
| FreeCAD | Python API | macOS/Win/Linux | Supported |
| OpenSCAD | SCAD Script | macOS/Win/Linux | Supported |
| AutoCAD | AutoLISP | macOS/Win | Supported |
| Revit | Dynamo / .NET API | Win | Supported |

### Industrial Design & CAM (3)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| ZW3D | Python API | Win | Supported |
| VoxelDance Additive | Python API | Win | Supported |
| Tinkercad | REST API | Web | Supported |

### Educational / Chinese 3D Software (3)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| 3D One | Python API | Win | Supported |
| Happy3D | Python API | Win | Supported |
| Maodou 3D | Python API | Win | Supported |

### FDM Slicers (4)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| UltiMaker Cura | CuraEngine CLI | macOS/Win/Linux | Supported |
| PrusaSlicer | CLI | macOS/Win/Linux | Supported |
| OrcaSlicer | CLI | macOS/Win/Linux | Supported |
| Simplify3D | CLI | macOS/Win | Supported |

### Resin Slicers (2)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| ChiTuBox | CLI | macOS/Win | Supported |
| Lychee Slicer | CLI | macOS/Win/Linux | Supported |

### 3D Print Management (7)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| MakerLab | Python API | Web | Supported |
| Creality Cloud | Python API | Web | Supported |
| FlashPrint | Python API | macOS/Win | Supported |
| Flash Studio | Python API | macOS/Win | Supported |
| Snapmaker Luban | Python API | macOS/Win | Supported |
| Snapmaker Orca | Python API | macOS/Win | Supported |
| Build Planner | Python API | Win | Supported |

### Specialty Printing (2)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| FlashDental | Python API | Win | Supported |
| WaxJetPrint | Python API | Win | Supported |

**Total: 39 supported software**

## Developer Guide

### Adding a New Plugin

1. Create a new Rust crate under `rust/plugins/`
2. Implement the `DesignPlugin` trait (see `rust/core/src/traits.rs`)
3. Add the crate to workspace members in `rust/Cargo.toml`
4. Generate Dart bindings via `flutter_rust_bridge`
5. Register in `lib/core/builtin_plugins.dart`
6. UI panels (`SoftwarePanel` and `PluginMarketplace`) auto-detect new plugins from `PluginManager` — no manual UI changes needed

See design docs: [Design Spec](docs/superpowers/specs/2026-07-30-ai-design-studio-design.md) | [Implementation Plan](docs/superpowers/plans/2026-07-30-ai-design-studio-plan.md)

### Configuration

**Model Routing** (`config/model-routing.yaml`):

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

**Environment Variables**:

| Variable | Description |
|----------|-------------|
| `FIGMA_ACCESS_TOKEN` | Figma Personal Access Token |
| `MESHY_API_KEY` | Meshy AI 3D generation API key |
| `TINKERCAD_ACCESS_TOKEN` | Tinkercad API access token |

## License

MIT
