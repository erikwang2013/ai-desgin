use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct Zw3DPlugin { meta: PluginMeta, capabilities: SoftwareCapabilities }

impl Default for Zw3DPlugin { fn default() -> Self { Self::new() } }

impl Zw3DPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.zw3d".into(), name: "中望3D".into(),
                version: env!("CARGO_PKG_VERSION").into(), script_language: "python".into(),
            },
            capabilities: SoftwareCapabilities {
                actions: vec!["创建草图".into(),"特征建模".into(),"装配设计".into(),"工程图".into(),"导出STEP".into()],
                file_formats: vec!["zw3d".into(),"step".into(),"iges".into(),"stl".into(),"dwg".into()],
                constraints: None,
            },
        }
    }
}

impl DesignPlugin for Zw3DPlugin {
    fn meta(&self) -> &PluginMeta { &self.meta }
    fn category(&self) -> DesignCategory { DesignCategory::Industrial }
    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> { Ok(()) }
    fn dispose(&mut self) {}
    fn check_connection(&self) -> ConnectionStatus { ConnectionStatus::Disconnected }
    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> { Ok(false) }
    fn capabilities(&self) -> &SoftwareCapabilities { &self.capabilities }
    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(Some(format!("[中望3D Python] 脚本已生成，请在中望3D中执行:\n\n{}", script)), vec![]))
    }
    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(Some(format!("[预览] 中望3D 脚本:\n{}", script)), vec![]))
    }
    fn get_current_state(&self) -> Result<SoftwareState, String> {
        Ok(SoftwareState { active_document: String::new(), selected_nodes: vec![], layers: vec![], extra: None })
    }
}
