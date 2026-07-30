pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};
use std::process::Command;

pub struct BlenderPlugin {
    meta: PluginMeta,
    blender_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for BlenderPlugin {
    fn default() -> Self {
        Self::new()
    }
}

impl BlenderPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.blender".into(),
                name: "Blender".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "python".into(),
            },
            blender_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建立方体".into(),
                    "创建球体".into(),
                    "创建平面".into(),
                    "添加材质".into(),
                    "设置渲染引擎".into(),
                    "导出FBX".into(),
                    "导出OBJ".into(),
                    "导出GLB".into(),
                    "添加灯光".into(),
                    "设置摄像机".into(),
                    "应用修改器".into(),
                    "绑定骨骼".into(),
                    "设置关键帧".into(),
                    "渲染图像".into(),
                ],
                file_formats: vec![
                    "blend".into(),
                    "fbx".into(),
                    "obj".into(),
                    "glb".into(),
                    "gltf".into(),
                    "stl".into(),
                    "ply".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_blender(&self) -> Option<String> {
        // Common Blender install paths
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\Blender Foundation\\Blender 4.0\\blender.exe",
            "C:\\Program Files\\Blender Foundation\\Blender 3.6\\blender.exe",
            "blender.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/Blender.app/Contents/MacOS/Blender",
            "blender",
        ];
        #[cfg(target_os = "linux")]
        let candidates = vec!["/usr/bin/blender", "/snap/bin/blender", "/usr/local/bin/blender"];

        for path in &candidates {
            if std::path::Path::new(path).exists() {
                return Some(path.to_string());
            }
        }
        if let Ok(output) = std::process::Command::new("which").arg("blender").output() {
            if output.status.success() {
                let path = String::from_utf8_lossy(&output.stdout).trim().to_string();
                if !path.is_empty() && std::path::Path::new(&path).exists() {
                    return Some(path);
                }
            }
        }
        None
    }
}

impl DesignPlugin for BlenderPlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }
    fn category(&self) -> DesignCategory {
        DesignCategory::ThreeD
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.blender_path = self.find_blender();
        Ok(())
    }

    fn dispose(&mut self) {
        self.blender_path = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        match self.blender_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.blender_path = self.find_blender();
        Ok(self.blender_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let blender_path = self
            .blender_path
            .as_ref()
            .ok_or("Blender not found. Please install Blender or configure the path.")?;

        let result = script::run_blender_script(blender_path, script)?;
        Ok(result)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将在 Blender 中执行 Python 脚本:\n{}",
                script
            )),
            vec![],
        ))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        let blender_path = self
            .blender_path
            .as_ref()
            .ok_or("Blender not found")?;

        let state_script = r#"
import bpy, json
state = {
    "active_document": bpy.data.filepath or "untitled.blend",
    "selected_nodes": [obj.name for obj in bpy.context.selected_objects],
    "layers": [obj.name for obj in bpy.data.objects],
}
print(json.dumps(state))
"#;
        let output = Command::new(blender_path)
            .args(["--background", "--python-expr", state_script])
            .output()
            .map_err(|e| format!("Failed to get Blender state: {}", e))?;

        let stdout = String::from_utf8_lossy(&output.stdout);
        // Parse JSON from stdout (Blender prints other info too, so find the JSON line)
        for line in stdout.lines() {
            if line.trim().starts_with('{') {
                if let Ok(state) = serde_json::from_str::<serde_json::Value>(line.trim()) {
                    return Ok(SoftwareState {
                        active_document: state["active_document"]
                            .as_str()
                            .unwrap_or("")
                            .into(),
                        selected_nodes: state["selected_nodes"]
                            .as_array()
                            .map(|a| {
                                a.iter()
                                    .filter_map(|v| v.as_str().map(String::from))
                                    .collect()
                            })
                            .unwrap_or_default(),
                        layers: state["layers"]
                            .as_array()
                            .map(|a| {
                                a.iter()
                                    .filter_map(|v| v.as_str().map(String::from))
                                    .collect()
                            })
                            .unwrap_or_default(),
                        extra: None,
                    });
                }
            }
        }

        Ok(SoftwareState {
            active_document: "untitled.blend".into(),
            selected_nodes: vec![],
            layers: vec![],
            extra: None,
        })
    }
}
