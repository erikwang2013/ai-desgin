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
┌──────────────────────────────────────────┐
│  Flutter UI (Dart)                       │
│  ChatView · TaskDashboard · SoftwarePanel│
├──────────────────────────────────────────┤
│  Core Layer (Dart)                        │
│  TaskOrchestrator · CCProcessManager     │
│  ModelRouter · PluginManager · Session   │
├──────────────────────────────────────────┤
│  Plugin Layer (Rust crates)               │
│  Figma · Blender · AutoCAD · Photoshop   │
│  (bridged via flutter_rust_bridge FFI)    │
└──────────────────────────────────────────┘
```

### Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| UI | Flutter 3.x + Material 3 | Cross-platform desktop UI |
| Core Logic | Dart | Task orchestration, model routing, session management |
| Plugins | Rust | System-level API calls, process management, script injection |
| Bridge | flutter_rust_bridge | Auto-generated Dart ↔ Rust FFI bindings |
| AI Engine | Claude Code CLI | Multi-model orchestration and script generation |
| Storage | SQLite (sqflite) | Session and task history persistence |

### Data Flow

```
User Input → TaskOrchestrator → CCProcessManager → Claude Code CLI
                                                       │
                                           ┌───────────┘
                                           ▼
                                   Model routing + script generation
                                           │
                                           ▼
                              Generated script ← PluginManager
                                           │
                                           ▼
                       Rust crate executes → Design software operation
                                           │
                                           ▼
                              Result/screenshot ← User confirmation
```

### Plugin Architecture

Each design software is an independent Rust crate implementing the `DesignPlugin` trait:

```
Dart (interface)  →  flutter_rust_bridge  →  Rust (execution)
                                                   │
                    ┌──────────────────────────────┼──────────────────────────┐
                    ▼                              ▼                          ▼
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
├── lib/
│   ├── main.dart                          # App entry point
│   ├── app.dart                           # MaterialApp + routing
│   ├── models/                            # Data models
│   ├── plugin_sdk/                        # Plugin interface
│   ├── core/                              # Core managers
│   │   ├── plugin_manager.dart            # Plugin registry
│   │   ├── model_router.dart              # Model routing engine
│   │   ├── cc_process_manager.dart        # Claude Code session mgmt
│   │   ├── cc_runner.dart                 # Claude Code subprocess
│   │   ├── task_orchestrator.dart         # Task orchestration
│   │   └── session_store.dart             # SQLite persistence
│   └── ui/                                # UI pages
├── rust/
│   ├── core/                              # Shared traits + types
│   └── plugins/                           # 17 software plugins
│       ├── figma/                         # Figma (REST API)
│       ├── photoshop/                     # Photoshop (ExtendScript)
│       ├── blender/                       # Blender (Python)
│       ├── fusion360/                     # Fusion 360 (Python)
│       ├── solidworks/                    # SolidWorks (VBA/COM)
│       ├── freecad/                       # FreeCAD (Python)
│       ├── openscad/                      # OpenSCAD (SCAD)
│       ├── rhino/                         # Rhino (Python)
│       ├── autocad/                       # AutoCAD (AutoLISP)
│       ├── tinkercad/                     # Tinkercad (REST)
│       ├── meshy/                         # Meshy (AI REST)
│       ├── cura/                          # Cura (CLI)
│       ├── prusaslicer/                   # PrusaSlicer (CLI)
│       ├── orcaslicer/                    # OrcaSlicer (CLI)
│       ├── simplify3d/                    # Simplify3D (CLI)
│       ├── chitubox/                      # ChiTuBox (CLI)
│       ├── lychee/                        # Lychee (CLI)
│       ├── illustrator/                   # Illustrator (ExtendScript)
│       ├── sketch/                        # Sketch (sketchtool/JS)
│       ├── revit/                         # Revit (Dynamo/.NET)
│       └── sketchup/                      # SketchUp (Ruby)
├── config/model-routing.yaml
├── scripts/                               # Build + release scripts
├── test/                                  # 49 Dart tests (all passing)
└── docs/
    ├── test-report-2026-07-31.md          # Test report
    ├── review-report-2026-07-31.md        # Code review
    └── superpowers/                       # Design specs + plans
```

## Quick Start

### Prerequisites

- **Flutter SDK** ≥ 3.x (with Windows/macOS build support)
- **Rust** ≥ 1.75 (Cargo + rustup)
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
flutter test                      # All Dart tests (49 tests, 100% passing)
cd rust && cargo build            # Rust compilation (18 crates, 0 warnings)
cd rust && cargo clippy           # Rust lint check
```

### Code Quality

| Check | Status |
|-------|--------|
| `flutter analyze` | No issues found |
| `flutter test` | 49/49 passed |
| `cargo build` | 18 crates compiled |
| `cargo clippy` | 0 warnings |

Detailed reports: [Review](docs/review-report-2026-07-31.md) | [Test](docs/test-report-2026-07-31.md)

## Usage

### 1. Connect Software

Open the app and check installed plugins in the Software Panel. Green indicator = connected, gray = not connected. Make sure your design software is running.

### 2. Select Domain

Choose a design domain from the sidebar. The AI will automatically select the optimal model and strategy:
- **Web** → Figma, Sketch
- **Advertising** → Photoshop, Illustrator
- **Industrial** → Fusion 360, SolidWorks
- **3D** → Blender, Maya
- **Architecture** → AutoCAD, Revit
- **Interior** → SketchUp, 3ds Max

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

Set up API endpoints and keys in Settings → Model Configuration. Customize routing rules in `config/model-routing.yaml`.

### Install Plugins

Browse available plugins in Settings → Plugin Marketplace. One-click install. New software entries appear in the Software Panel immediately.

## Features

### Graphic & UI Design

Automate Figma and Photoshop operations. AI can create canvases, add layers, apply styles, export assets, and convert designs directly to HTML/CSS code.

### 3D Modeling & CAD

Covering parametric modeling, polygonal modeling, and NURBS surface modeling. AI can auto-create parts, assemblies, generate technical drawings, and export STL/STEP formats for 3D printing.

### 3D Print Slicing

Full support for FDM and resin printing workflows. AI automatically configures layer height, infill density, and support structures based on model complexity, generating GCode or CTB slice files in one click.

### AI Model Generation

Text-to-3D and image-to-3D generation via Meshy API, with automatic polygon optimization, texture generation, and multi-format export.

## Supported Software

### Graphic & UI Design (4)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| Figma | REST API | Web/macOS/Win | ✅ |
| Photoshop | ExtendScript + COM/AppleScript | macOS/Win | ✅ |
| Sketch | sketchtool CLI + osascript | macOS | ✅ |
| Illustrator | ExtendScript | macOS/Win | ✅ |

### CAD & BIM Modeling (9)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| Fusion 360 | Python API | macOS/Win | ✅ |
| SolidWorks | VBA/COM | Win | ✅ |
| FreeCAD | Python API | macOS/Win/Linux | ✅ |
| OpenSCAD | SCAD Script | macOS/Win/Linux | ✅ |
| Rhino | Python/RhinoScript | macOS/Win | ✅ |
| Blender | Python bpy | macOS/Win/Linux | ✅ |
| AutoCAD | AutoLISP | macOS/Win | ✅ |
| Revit | Dynamo / .NET API | Win | ✅ |
| SketchUp | Ruby API | macOS/Win | ✅ |

### FDM Slicers (4)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| UltiMaker Cura | CuraEngine CLI | macOS/Win/Linux | ✅ |
| PrusaSlicer | CLI | macOS/Win/Linux | ✅ |
| OrcaSlicer | CLI | macOS/Win/Linux | ✅ |
| Simplify3D | CLI | macOS/Win | ✅ |

### Resin Slicers (2)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| ChiTuBox | CLI | macOS/Win | ✅ |
| Lychee Slicer | CLI | macOS/Win/Linux | ✅ |

### Web / AI (2)

| Software | Control Method | Platform | Status |
|----------|---------------|----------|--------|
| Tinkercad | REST API | Web | ✅ |
| Meshy | REST API (AI Generation) | Web | ✅ |

### Planned

| Software | Control Method | Platform |
|----------|---------------|----------|
| Maya | Python API | macOS/Win/Linux |
| 3ds Max | MAXScript | Win |
| Cinema 4D | Python API | macOS/Win |
| InDesign | ExtendScript | macOS/Win |

## Developer Guide

### Adding a New Plugin

1. Create a new Rust crate under `rust/plugins/`
2. Implement the `DesignPlugin` trait (see `rust/core/src/traits.rs`)
3. Add the crate to workspace members in `rust/Cargo.toml`
4. Generate Dart bindings via `flutter_rust_bridge`

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
