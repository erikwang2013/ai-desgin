pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct Fusion360Plugin {
    meta: PluginMeta,
    fusion360_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Fusion360Plugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.fusion360".into(),
                name: "Fusion 360".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "python".into(),
            },
            fusion360_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建草图".into(),
                    "拉伸实体".into(),
                    "创建圆角".into(),
                    "打孔".into(),
                    "创建螺纹".into(),
                    "装配组件".into(),
                    "生成工程图".into(),
                    "导出STL".into(),
                    "导出STEP".into(),
                    "导出F3D".into(),
                ],
                file_formats: vec![
                    "f3d".into(),
                    "stl".into(),
                    "step".into(),
                    "iges".into(),
                    "obj".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_fusion360(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\Autodesk\\Fusion 360\\Fusion360.exe",
            "C:\\Program Files (x86)\\Autodesk\\Fusion 360\\Fusion360.exe",
            "Fusion360.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/Autodesk/Fusion 360.app/Contents/MacOS/Fusion 360",
            "/Applications/Autodesk Fusion 360.app/Contents/MacOS/Autodesk Fusion 360",
        ];
        #[cfg(target_os = "linux")]
        let candidates: Vec<&str> = vec![];

        for path in &candidates {
            if std::path::Path::new(path).exists() {
                return Some(path.to_string());
            }
        }
        None
    }
}

impl DesignPlugin for Fusion360Plugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }

    fn category(&self) -> DesignCategory {
        DesignCategory::Industrial
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.fusion360_path = self.find_fusion360();
        Ok(())
    }

    fn dispose(&mut self) {
        self.fusion360_path = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        match self.fusion360_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            Some(_) => ConnectionStatus::Disconnected,
            None => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.fusion360_path = self.find_fusion360();
        Ok(self.fusion360_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let fusion360_path = self
            .fusion360_path
            .as_ref()
            .ok_or("Fusion 360 not found. Please install Fusion 360 or configure the path.")?;

        script::run_fusion360_script(fusion360_path, script)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将在 Fusion 360 中执行 Python 脚本:\n{}",
                script
            )),
            vec![],
        ))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        let fusion360_path = self
            .fusion360_path
            .as_ref()
            .ok_or("Fusion 360 not found")?;

        // Query current state via Fusion 360 Python API
        let python_script = r#"import adsk.core, adsk.fusion, json, traceback
app = adsk.core.Application.get()
if app:
    design = app.activeProduct
    doc_name = app.activeDocument.name if app.activeDocument else ""
    result = json.dumps({"active_document": doc_name, "selected_nodes": [], "layers": []})
    print(result)
else:
    print('{"active_document":"","selected_nodes":[],"layers":[]}')
"#;

        let result = script::run_fusion360_script(fusion360_path, python_script)?;

        if let Some(ref output) = result.output {
            for line in output.lines() {
                let trimmed = line.trim();
                if trimmed.starts_with('{') {
                    if let Ok(state) =
                        serde_json::from_str::<serde_json::Value>(trimmed)
                    {
                        return Ok(SoftwareState {
                            active_document: state["active_document"]
                                .as_str()
                                .unwrap_or("")
                                .into(),
                            selected_nodes: vec![],
                            layers: vec![],
                            extra: None,
                        });
                    }
                }
            }
        }

        Ok(SoftwareState {
            active_document: String::new(),
            selected_nodes: vec![],
            layers: vec![],
            extra: None,
        })
    }
}
