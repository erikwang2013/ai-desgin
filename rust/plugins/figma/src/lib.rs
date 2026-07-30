pub mod api;
pub mod browser;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct FigmaPlugin {
    meta: PluginMeta,
    access_token: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for FigmaPlugin {
    fn default() -> Self {
        Self::new()
    }
}

impl FigmaPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.figma".into(),
                name: "Figma".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "javascript".into(),
            },
            access_token: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建画布".into(),
                    "添加矩形".into(),
                    "添加文本".into(),
                    "设置填充色".into(),
                    "导出PNG".into(),
                    "导出SVG".into(),
                    "获取图层列表".into(),
                    "修改图层属性".into(),
                    "创建组件".into(),
                    "应用自动布局".into(),
                ],
                file_formats: vec!["fig".into(), "png".into(), "svg".into(), "pdf".into()],
                constraints: None,
            },
        }
    }
}

impl DesignPlugin for FigmaPlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }

    fn category(&self) -> DesignCategory {
        DesignCategory::Web
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.access_token = std::env::var("FIGMA_ACCESS_TOKEN").ok();
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
            api::execute_figma_script(self.access_token.as_deref().unwrap_or(""), script).await
        })
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!("[预览] 即将执行的脚本:\n{}", script)),
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
