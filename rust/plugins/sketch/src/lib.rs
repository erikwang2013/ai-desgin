pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct SketchPlugin {
    meta: PluginMeta,
    sketch_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for SketchPlugin {
    fn default() -> Self { Self::new() }
}

impl SketchPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.sketch".into(),
                name: "Sketch".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "javascript".into(),
            },
            sketch_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建画板".into(), "添加形状".into(), "添加文本".into(),
                    "设置样式".into(), "导出切片".into(), "创建组件".into(),
                    "应用样式".into(), "管理图层".into(), "创建符号".into(),
                    "导出PDF".into(), "导出PNG".into(), "导出SVG".into(),
                ],
                file_formats: vec![
                    "sketch".into(), "png".into(), "svg".into(),
                    "pdf".into(), "jpg".into(), "eps".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_sketch(&self) -> Option<String> {
        #[cfg(target_os = "macos")]
        let candidates = vec!["/Applications/Sketch.app"];
        #[cfg(not(target_os = "macos"))]
        let candidates: Vec<&str> = vec![];

        for path in &candidates {
            if std::path::Path::new(path).exists() {
                return Some(path.to_string());
            }
        }
        None
    }
}

impl DesignPlugin for SketchPlugin {
    fn meta(&self) -> &PluginMeta { &self.meta }
    fn category(&self) -> DesignCategory { DesignCategory::Web }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.sketch_path = self.find_sketch();
        if self.sketch_path.is_none() {
            return Err("Sketch requires macOS.".into());
        }
        Ok(())
    }

    fn dispose(&mut self) { self.sketch_path = None; }

    fn check_connection(&self) -> ConnectionStatus {
        match self.sketch_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.sketch_path = self.find_sketch();
        Ok(self.sketch_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities { &self.capabilities }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let path = self.sketch_path.as_ref()
            .ok_or("Sketch not found on macOS.")?;
        script::run_sketch_script(path, script)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!("[预览] Sketch 脚本:\n{}", script)),
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
