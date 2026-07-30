pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct ChiTuBoxPlugin {
    meta: PluginMeta,
    chitubox_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for ChiTuBoxPlugin {
    fn default() -> Self {
        Self::new()
    }
}

impl ChiTuBoxPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.chitubox".into(),
                name: "ChiTuBox".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "cli".into(),
            },
            chitubox_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "导入STL".into(),
                    "自动支撑".into(),
                    "挖空".into(),
                    "打孔".into(),
                    "切片".into(),
                    "导出CTB".into(),
                    "导出CBDDLP".into(),
                ],
                file_formats: vec![
                    "stl".into(),
                    "obj".into(),
                    "ctb".into(),
                    "cbddlp".into(),
                    "photon".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_chitubox(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\CHITUBOX\\CHITUBOX.exe",
            "C:\\Program Files\\CBD\\CHITUBOX\\CHITUBOX.exe",
            "CHITUBOX.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/CHITUBOX.app/Contents/MacOS/CHITUBOX",
            "chitubox",
        ];
        #[cfg(target_os = "linux")]
        let candidates = vec![
            "chitubox",
            "/usr/local/bin/chitubox",
            "/opt/chitubox/chitubox",
        ];

        for path in &candidates {
            if std::path::Path::new(path).exists() {
                return Some(path.to_string());
            }
        }
        None
    }
}

impl DesignPlugin for ChiTuBoxPlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }

    fn category(&self) -> DesignCategory {
        DesignCategory::Industrial
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.chitubox_path = self.find_chitubox();
        Ok(())
    }

    fn dispose(&mut self) {
        self.chitubox_path = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        match self.chitubox_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.chitubox_path = self.find_chitubox();
        Ok(self.chitubox_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let chitubox_path = self
            .chitubox_path
            .as_ref()
            .ok_or("ChiTuBox not found. Please install ChiTuBox or configure the path.")?;

        script::run_chitubox_command(chitubox_path, script)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将在 ChiTuBox 中执行:\n{}",
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
