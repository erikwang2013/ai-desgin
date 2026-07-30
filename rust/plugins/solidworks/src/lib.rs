pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct SolidWorksPlugin {
    meta: PluginMeta,
    solidworks_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for SolidWorksPlugin {
    fn default() -> Self {
        Self::new()
    }
}

impl SolidWorksPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.solidworks".into(),
                name: "SolidWorks".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "vba".into(),
            },
            solidworks_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建草图".into(),
                    "拉伸凸台".into(),
                    "旋转特征".into(),
                    "创建装配体".into(),
                    "生成工程图".into(),
                    "添加尺寸".into(),
                    "导出STL".into(),
                    "导出STEP".into(),
                    "导出SLDPRT".into(),
                ],
                file_formats: vec![
                    "sldprt".into(),
                    "sldasm".into(),
                    "stl".into(),
                    "step".into(),
                    "iges".into(),
                ],
                constraints: None,
            },
        }
    }

    /// Find SolidWorks executable at common Windows installation paths.
    /// SolidWorks is Windows-only, no paths for macOS/Linux are provided.
    fn find_solidworks(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\SOLIDWORKS Corp\\SOLIDWORKS\\SLDWORKS.exe",
            "C:\\Program Files (x86)\\SOLIDWORKS Corp\\SOLIDWORKS\\SLDWORKS.exe",
            "SLDWORKS.exe",
        ];
        #[cfg(not(target_os = "windows"))]
        let candidates: Vec<&str> = vec![];

        for path in &candidates {
            if std::path::Path::new(path).exists() {
                return Some(path.to_string());
            }
        }
        None
    }
}

impl DesignPlugin for SolidWorksPlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }

    fn category(&self) -> DesignCategory {
        DesignCategory::Industrial
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.solidworks_path = self.find_solidworks();
        Ok(())
    }

    fn dispose(&mut self) {
        self.solidworks_path = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        match self.solidworks_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            Some(_) => ConnectionStatus::Disconnected,
            None => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.solidworks_path = self.find_solidworks();
        Ok(self.solidworks_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let solidworks_path = self.solidworks_path.as_ref().ok_or(
            "SolidWorks not found. Please install SolidWorks or configure the path.",
        )?;

        script::run_solidworks_script(solidworks_path, script)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将在 SolidWorks 中执行 VBA 宏脚本:\n{}",
                script
            )),
            vec![],
        ))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        let solidworks_path = self
            .solidworks_path
            .as_ref()
            .ok_or("SolidWorks not found")?;

        // Query current document via VBScript COM automation
        let vbscript = r#"
Dim swApp
Set swApp = CreateObject("SldWorks.Application")
Dim swModel
Set swModel = swApp.ActiveDoc
Dim docName
If Not swModel Is Nothing Then
    docName = swModel.GetTitle()
Else
    docName = ""
End If
WScript.Echo "{""active_document"":""" & docName & """,""selected_nodes"":[],""layers"":[]}"
"#;

        let result = script::run_solidworks_script(solidworks_path, vbscript)?;

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
