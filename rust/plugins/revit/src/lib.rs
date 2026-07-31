pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct RevitPlugin {
    meta: PluginMeta,
    revit_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for RevitPlugin {
    fn default() -> Self { Self::new() }
}

impl RevitPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.revit".into(),
                name: "Revit".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "python".into(),
            },
            revit_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建墙体".into(), "创建楼板".into(), "创建屋顶".into(),
                    "创建门窗".into(), "创建柱".into(), "创建标高".into(),
                    "创建轴网".into(), "放置族".into(), "修改参数".into(),
                    "导出IFC".into(), "导出DWG".into(), "创建图纸".into(),
                    "添加标注".into(), "创建明细表".into(), "渲染视图".into(),
                ],
                file_formats: vec![
                    "rvt".into(), "rfa".into(), "ifc".into(), "dwg".into(),
                    "dxf".into(), "nwc".into(), "pdf".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_revit(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\Autodesk\\Revit 2025\\Revit.exe",
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

impl DesignPlugin for RevitPlugin {
    fn meta(&self) -> &PluginMeta { &self.meta }
    fn category(&self) -> DesignCategory { DesignCategory::Arch }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.revit_path = self.find_revit();
        if self.revit_path.is_none() {
            return Err("Revit requires Windows.".into());
        }
        Ok(())
    }

    fn dispose(&mut self) { self.revit_path = None; }

    fn check_connection(&self) -> ConnectionStatus {
        match self.revit_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.revit_path = self.find_revit();
        Ok(self.revit_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities { &self.capabilities }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let path = self.revit_path.as_ref()
            .ok_or("Revit not found on Windows.")?;
        script::run_revit_script(path, script)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!("[预览] Revit .NET 脚本:\n{}", script)),
            vec![],
        ))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        Ok(SoftwareState {
            active_document: String::new(), selected_nodes: vec![],
            layers: vec![], extra: None,
        })
    }
}
