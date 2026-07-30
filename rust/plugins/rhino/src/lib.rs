pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct RhinoPlugin {
    meta: PluginMeta,
    rhino_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl RhinoPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.rhino".into(),
                name: "Rhinoceros 3D".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "python".into(),
            },
            rhino_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建曲线".into(),
                    "创建曲面".into(),
                    "放样".into(),
                    "扫描".into(),
                    "布尔运算".into(),
                    "网格转换".into(),
                    "导出STL".into(),
                    "导出STEP".into(),
                    "导出3DM".into(),
                    "分析曲率".into(),
                ],
                file_formats: vec![
                    "3dm".into(),
                    "stl".into(),
                    "step".into(),
                    "iges".into(),
                    "obj".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_rhino(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\Rhino 8\\System\\rhino.exe",
            "C:\\Program Files\\Rhino 7\\System\\rhino.exe",
            "C:\\Program Files\\Rhinoceros 8\\System\\rhino.exe",
            "rhino.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/Rhino 8.app/Contents/MacOS/Rhino",
            "/Applications/Rhino 7.app/Contents/MacOS/Rhino",
            "/Applications/Rhinoceros.app/Contents/MacOS/Rhinoceros",
            "rhino",
        ];
        #[cfg(target_os = "linux")]
        let candidates = vec!["rhino"];

        for path in &candidates {
            if std::path::Path::new(path).exists() {
                return Some(path.to_string());
            }
        }
        None
    }
}

impl DesignPlugin for RhinoPlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }

    fn category(&self) -> DesignCategory {
        DesignCategory::Industrial
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.rhino_path = self.find_rhino();
        Ok(())
    }

    fn dispose(&mut self) {
        self.rhino_path = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        match self.rhino_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.rhino_path = self.find_rhino();
        Ok(self.rhino_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let rhino_path = self
            .rhino_path
            .as_ref()
            .ok_or("Rhino not found. Please install Rhino 3D or configure the path.")?;

        let result = script::run_rhino_script(rhino_path, script)?;
        Ok(result)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将在 Rhino 中执行 Python 脚本:\n{}",
                script
            )),
            vec![],
        ))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        let rhino_path = self
            .rhino_path
            .as_ref()
            .ok_or("Rhino not found")?;

        let state_script = r#"
import rhinoscriptsyntax as rs, json
state = {
    "active_document": rs.DocumentName() or "untitled.3dm",
    "selected_nodes": rs.GetObjects() or [],
    "layers": rs.LayerNames() or [],
}
print(json.dumps(state))
"#;
        let result = script::run_rhino_script(rhino_path, state_script)?;
        if let Some(ref output) = result.output {
            for line in output.lines() {
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
        }

        Ok(SoftwareState {
            active_document: "untitled.3dm".into(),
            selected_nodes: vec![],
            layers: vec![],
            extra: None,
        })
    }
}
