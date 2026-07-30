pub mod api;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct TinkercadPlugin {
    meta: PluginMeta,
    access_token: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl TinkercadPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.tinkercad".into(),
                name: "Tinkercad".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "javascript".into(),
            },
            access_token: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建形状".into(),
                    "组合形状".into(),
                    "导出STL".into(),
                    "导出OBJ".into(),
                    "导出GLB".into(),
                    "导入SVG".into(),
                ],
                file_formats: vec!["stl".into(), "obj".into(), "glb".into(), "svg".into()],
                constraints: None,
            },
        }
    }
}

impl DesignPlugin for TinkercadPlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }

    fn category(&self) -> DesignCategory {
        DesignCategory::Industrial
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.access_token = std::env::var("TINKERCAD_ACCESS_TOKEN").ok();
        Ok(())
    }

    fn dispose(&mut self) {
        self.access_token = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        if self.access_token.is_some() {
            ConnectionStatus::Connected
        } else {
            ConnectionStatus::Disconnected
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        Ok(self.access_token.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let rt = tokio::runtime::Runtime::new().map_err(|e| e.to_string())?;
        rt.block_on(async {
            api::execute_tinkercad_script(self.access_token.as_deref().unwrap_or(""), script).await
        })
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将在 Tinkercad 中执行 JavaScript ShapeScript:\n{}",
                script
            )),
            vec![],
        ))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        Ok(SoftwareState {
            active_document: String::new(),
            selected_nodes: vec![],
            layers: vec![],
            extra: None,
        })
    }
}
