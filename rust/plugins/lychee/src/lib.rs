pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct LycheePlugin {
    meta: PluginMeta,
    lychee_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for LycheePlugin {
    fn default() -> Self {
        Self::new()
    }
}

impl LycheePlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.lychee".into(),
                name: "Lychee Slicer".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "cli".into(),
            },
            lychee_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "导入模型".into(),
                    "自动布局".into(),
                    "自动支撑(树脂)".into(),
                    "切片(树脂)".into(),
                    "切片(FDM)".into(),
                    "导出CTB".into(),
                    "导出GCode".into(),
                ],
                file_formats: vec![
                    "stl".into(),
                    "obj".into(),
                    "3mf".into(),
                    "ctb".into(),
                    "gcode".into(),
                    "lys".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_lychee(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\Lychee Slicer\\Lychee-Slicer.exe",
            "C:\\Program Files\\Mango\\Lychee Slicer\\Lychee-Slicer.exe",
            "lychee-slicer.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/Lychee Slicer.app/Contents/MacOS/Lychee-Slicer",
            "lychee-slicer",
        ];
        #[cfg(target_os = "linux")]
        let candidates = vec![
            "lychee-slicer",
            "/usr/local/bin/lychee-slicer",
            "/opt/lychee-slicer/lychee-slicer",
        ];

        for path in &candidates {
            if std::path::Path::new(path).exists() {
                return Some(path.to_string());
            }
        }
        None
    }
}

impl DesignPlugin for LycheePlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }

    fn category(&self) -> DesignCategory {
        DesignCategory::Industrial
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.lychee_path = self.find_lychee();
        Ok(())
    }

    fn dispose(&mut self) {
        self.lychee_path = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        match self.lychee_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.lychee_path = self.find_lychee();
        Ok(self.lychee_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let lychee_path = self
            .lychee_path
            .as_ref()
            .ok_or("Lychee Slicer not found. Please install Lychee Slicer or configure the path.")?;

        script::run_lychee_command(lychee_path, script)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将在 Lychee Slicer 中执行:\n{}",
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
