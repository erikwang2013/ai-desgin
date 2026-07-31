pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct IllustratorPlugin {
    meta: PluginMeta,
    illustrator_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for IllustratorPlugin {
    fn default() -> Self { Self::new() }
}

impl IllustratorPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.illustrator".into(),
                name: "Illustrator".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "javascript".into(),
            },
            illustrator_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建画板".into(), "添加形状".into(), "添加文字".into(),
                    "创建路径".into(), "设置填充色".into(), "设置描边".into(),
                    "应用效果".into(), "导出PNG".into(), "导出SVG".into(),
                    "导出PDF".into(), "图层管理".into(), "组合对象".into(),
                    "创建符号".into(), "文本绕排".into(),
                ],
                file_formats: vec![
                    "ai".into(), "eps".into(), "pdf".into(), "svg".into(),
                    "png".into(), "jpg".into(), "dxf".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_illustrator(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\Adobe\\Adobe Illustrator 2025\\Support Files\\Contents\\Windows\\Illustrator.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/Adobe Illustrator 2025/Adobe Illustrator.app",
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

impl DesignPlugin for IllustratorPlugin {
    fn meta(&self) -> &PluginMeta { &self.meta }
    fn category(&self) -> DesignCategory { DesignCategory::Ad }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.illustrator_path = self.find_illustrator();
        Ok(())
    }

    fn dispose(&mut self) { self.illustrator_path = None; }

    fn check_connection(&self) -> ConnectionStatus {
        match self.illustrator_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.illustrator_path = self.find_illustrator();
        Ok(self.illustrator_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities { &self.capabilities }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let path = self.illustrator_path.as_ref()
            .ok_or("Illustrator not found.")?;
        script::run_extendscript(path, script)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!("[预览] Illustrator ExtendScript:\n{}", script)),
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
