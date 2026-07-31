use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct InDesignPlugin { meta: PluginMeta, capabilities: SoftwareCapabilities }

impl Default for InDesignPlugin { fn default() -> Self { Self::new() } }

impl InDesignPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.indesign".into(), name: "InDesign".into(),
                version: env!("CARGO_PKG_VERSION").into(), script_language: "javascript".into(),
            },
            capabilities: SoftwareCapabilities {
                actions: vec!["创建文档".into(),"文本排版".into(),"图像置入".into(),"主页设置".into(),"导出PDF".into()],
                file_formats: vec!["indd".into(),"idml".into(),"pdf".into(),"epub".into()],
                constraints: None,
            },
        }
    }
}

impl DesignPlugin for InDesignPlugin {
    fn meta(&self) -> &PluginMeta { &self.meta }
    fn category(&self) -> DesignCategory { DesignCategory::Ad }
    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> { Ok(()) }
    fn dispose(&mut self) {}
    fn check_connection(&self) -> ConnectionStatus { ConnectionStatus::Disconnected }
    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> { Ok(false) }
    fn capabilities(&self) -> &SoftwareCapabilities { &self.capabilities }
    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(Some(format!("[InDesign ExtendScript] 脚本已生成，请在 Scripts 面板中执行:\n\n{}", script)), vec![]))
    }
    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(Some(format!("[预览] InDesign 脚本:\n{}", script)), vec![]))
    }
    fn get_current_state(&self) -> Result<SoftwareState, String> {
        Ok(SoftwareState { active_document: String::new(), selected_nodes: vec![], layers: vec![], extra: None })
    }
}
