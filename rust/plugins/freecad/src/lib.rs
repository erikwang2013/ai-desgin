pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct FreeCADPlugin {
    meta: PluginMeta,
    freecad_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for FreeCADPlugin {
    fn default() -> Self {
        Self::new()
    }
}

impl FreeCADPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.freecad".into(),
                name: "FreeCAD".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "python".into(),
            },
            freecad_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建零件".into(),
                    "创建草图".into(),
                    "拉伸".into(),
                    "旋转".into(),
                    "布尔运算".into(),
                    "导出STL".into(),
                    "导出STEP".into(),
                    "导出OBJ".into(),
                    "网格修复".into(),
                ],
                file_formats: vec![
                    "fcstd".into(),
                    "stl".into(),
                    "step".into(),
                    "obj".into(),
                    "iges".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_freecad(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\FreeCAD 0.21\\bin\\FreeCADCmd.exe",
            "C:\\Program Files\\FreeCAD 0.20\\bin\\FreeCADCmd.exe",
            "C:\\Program Files\\FreeCAD 1.0\\bin\\FreeCADCmd.exe",
            "freecad.exe",
            "FreeCADCmd.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/FreeCAD.app/Contents/MacOS/FreeCADCmd",
            "/Applications/FreeCAD.app/Contents/MacOS/FreeCAD",
            "/usr/local/bin/freecad",
            "freecad",
        ];
        #[cfg(target_os = "linux")]
        let candidates = vec![
            "freecad",
            "freecadcmd",
            "/usr/bin/freecad",
            "/usr/bin/freecadcmd",
            "/snap/bin/freecad",
            "/var/lib/flatpak/exports/bin/org.freecad.FreeCAD",
        ];

        for path in &candidates {
            if std::path::Path::new(path).exists() {
                return Some(path.to_string());
            }
        }
        None
    }
}

impl DesignPlugin for FreeCADPlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }

    fn category(&self) -> DesignCategory {
        DesignCategory::Industrial
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.freecad_path = self.find_freecad();
        Ok(())
    }

    fn dispose(&mut self) {
        self.freecad_path = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        match self.freecad_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.freecad_path = self.find_freecad();
        Ok(self.freecad_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let freecad_path = self
            .freecad_path
            .as_ref()
            .ok_or("FreeCAD not found. Please install FreeCAD or configure the path.")?;

        let result = script::run_freecad_script(freecad_path, script)?;
        Ok(result)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将在 FreeCAD 中以 headless 模式执行 Python 脚本:\n{}",
                script
            )),
            vec![],
        ))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        let freecad_path = self
            .freecad_path
            .as_ref()
            .ok_or("FreeCAD not found")?;

        let state_script = r#"
import FreeCAD, json
state = {}
if FreeCAD.ActiveDocument:
    state["active_document"] = FreeCAD.ActiveDocument.Label
    state["selected_nodes"] = [o.Label for o in FreeCAD.ActiveDocument.Objects]
    state["layers"] = [o.Name for o in FreeCAD.ActiveDocument.Objects]
else:
    state["active_document"] = "untitled.fcstd"
    state["selected_nodes"] = []
    state["layers"] = []
print(json.dumps(state))
"#;
        let result = script::run_freecad_script(freecad_path, state_script)?;
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
            active_document: "untitled.fcstd".into(),
            selected_nodes: vec![],
            layers: vec![],
            extra: None,
        })
    }
}
