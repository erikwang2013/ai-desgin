pub mod api;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct MeshyPlugin {
    meta: PluginMeta,
    api_key: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl MeshyPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.meshy".into(),
                name: "Meshy".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "rest".into(),
            },
            api_key: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "文字生成3D".into(),
                    "图片生成3D".into(),
                    "纹理生成".into(),
                    "模型优化".into(),
                    "导出GLB".into(),
                    "导出FBX".into(),
                    "导出OBJ".into(),
                ],
                file_formats: vec![
                    "glb".into(),
                    "fbx".into(),
                    "obj".into(),
                    "stl".into(),
                    "usdz".into(),
                ],
                constraints: None,
            },
        }
    }
}

impl DesignPlugin for MeshyPlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }

    fn category(&self) -> DesignCategory {
        DesignCategory::ThreeD
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.api_key = std::env::var("MESHY_API_KEY").ok();
        Ok(())
    }

    fn dispose(&mut self) {
        self.api_key = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        if self.api_key.is_some() {
            ConnectionStatus::Connected
        } else {
            ConnectionStatus::Disconnected
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        Ok(self.api_key.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let rt = tokio::runtime::Runtime::new().map_err(|e| e.to_string())?;
        rt.block_on(async {
            api::execute_meshy_request(self.api_key.as_deref().unwrap_or(""), script).await
        })
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将向 Meshy API 发送请求:\n{}",
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
