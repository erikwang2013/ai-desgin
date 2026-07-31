pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct SketchUpPlugin {
    meta: PluginMeta,
    sketchup_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for SketchUpPlugin {
    fn default() -> Self { Self::new() }
}

impl SketchUpPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.sketchup".into(),
                name: "SketchUp".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "ruby".into(),
            },
            sketchup_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建墙体".into(), "创建楼板".into(), "创建立方体".into(),
                    "创建圆柱体".into(), "推拉面".into(), "移动组件".into(),
                    "应用材质".into(), "创建组".into(), "导出DAE".into(),
                    "导出OBJ".into(), "导出STL".into(), "设置场景".into(),
                    "添加标注".into(), "创建剖面".into(), "渲染视图".into(),
                ],
                file_formats: vec![
                    "skp".into(), "dae".into(), "obj".into(), "stl".into(),
                    "3ds".into(), "fbx".into(), "kmz".into(), "pdf".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_sketchup(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\SketchUp\\SketchUp 2025\\SketchUp.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/SketchUp 2025/SketchUp.app",
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

impl DesignPlugin for SketchUpPlugin {
    fn meta(&self) -> &PluginMeta { &self.meta }
    fn category(&self) -> DesignCategory { DesignCategory::Interior }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.sketchup_path = self.find_sketchup();
        Ok(())
    }

    fn dispose(&mut self) { self.sketchup_path = None; }

    fn check_connection(&self) -> ConnectionStatus {
        match self.sketchup_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.sketchup_path = self.find_sketchup();
        Ok(self.sketchup_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities { &self.capabilities }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let path = self.sketchup_path.as_ref()
            .ok_or("SketchUp not found.")?;
        script::run_sketchup_script(path, script)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!("[预览] SketchUp Ruby 脚本:\n{}", script)),
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
