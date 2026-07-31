use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct FlashDentalPlugin { meta: PluginMeta, capabilities: SoftwareCapabilities }

impl Default for FlashDentalPlugin { fn default() -> Self { Self::new() } }

impl FlashDentalPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.flashdental".into(), name: "FlashDental".into(),
                version: env!("CARGO_PKG_VERSION").into(), script_language: "python".into(),
            },
            capabilities: SoftwareCapabilities {
                actions: vec!["牙模导入".into(),"模型编辑".into(),"支撑生成".into(),"切片".into(),"导出GCode".into()],
                file_formats: vec!["stl".into(),"3mf".into(),"gcode".into()],
                constraints: None,
            },
        }
    }
}

impl DesignPlugin for FlashDentalPlugin {
    fn meta(&self) -> &PluginMeta { &self.meta }
    fn category(&self) -> DesignCategory { DesignCategory::Industrial }
    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> { Ok(()) }
    fn dispose(&mut self) {}
    fn check_connection(&self) -> ConnectionStatus { ConnectionStatus::Disconnected }
    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> { Ok(false) }
    fn capabilities(&self) -> &SoftwareCapabilities { &self.capabilities }
    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(Some(format!("[FlashDental] 脚本已生成:\n\n{}", script)), vec![]))
    }
    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(Some(format!("[预览] FlashDental 脚本:\n{}", script)), vec![]))
    }
    fn get_current_state(&self) -> Result<SoftwareState, String> {
        Ok(SoftwareState { active_document: String::new(), selected_nodes: vec![], layers: vec![], extra: None })
    }
}
