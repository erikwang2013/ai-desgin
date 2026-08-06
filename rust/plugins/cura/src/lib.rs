pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};
use std::process::Command;

pub struct CuraPlugin {
    meta: PluginMeta,
    cura_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for CuraPlugin {
    fn default() -> Self {
        Self::new()
    }
}

impl CuraPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.cura".into(),
                name: "UltiMaker Cura".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "cli".into(),
            },
            cura_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "导入STL".into(),
                    "设置层高".into(),
                    "设置填充密度".into(),
                    "设置支撑".into(),
                    "切片生成GCode".into(),
                    "导出GCode".into(),
                    "预览切片".into(),
                ],
                file_formats: vec![
                    "stl".into(),
                    "obj".into(),
                    "3mf".into(),
                    "gcode".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_cura(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\UltiMaker Cura 5.0\\CuraEngine.exe",
            "C:\\Program Files\\UltiMaker Cura 5.1\\CuraEngine.exe",
            "C:\\Program Files\\UltiMaker Cura 5.2\\CuraEngine.exe",
            "C:\\Program Files\\UltiMaker Cura 5.3\\CuraEngine.exe",
            "C:\\Program Files\\UltiMaker Cura 5.4\\CuraEngine.exe",
            "C:\\Program Files\\UltiMaker Cura 5.5\\CuraEngine.exe",
            "C:\\Program Files\\UltiMaker Cura 5.6\\CuraEngine.exe",
            "C:\\Program Files\\UltiMaker Cura 5.7\\CuraEngine.exe",
            "C:\\Program Files\\UltiMaker Cura 5.8\\CuraEngine.exe",
            "C:\\Program Files\\UltiMaker Cura 5.9\\CuraEngine.exe",
            "C:\\Program Files\\UltiMaker Cura 6.0\\CuraEngine.exe",
            "CuraEngine.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/UltiMaker Cura.app/Contents/MacOS/CuraEngine",
            "/Applications/Cura.app/Contents/MacOS/CuraEngine",
            "CuraEngine",
        ];
        #[cfg(target_os = "linux")]
        let candidates = vec![
            "CuraEngine",
            "/usr/bin/CuraEngine",
            "/usr/local/bin/CuraEngine",
            "/snap/bin/curaengine",
        ];

        for path in &candidates {
            if std::path::Path::new(path).exists() {
                return Some(path.to_string());
            }
        }
        None
    }
}

impl DesignPlugin for CuraPlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }
    fn category(&self) -> DesignCategory {
        DesignCategory::Industrial
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.cura_path = self.find_cura();
        Ok(())
    }

    fn dispose(&mut self) {
        self.cura_path = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        match self.cura_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.cura_path = self.find_cura();
        Ok(self.cura_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let cura_path = self
            .cura_path
            .as_ref()
            .ok_or("CuraEngine not found. Please install UltiMaker Cura or configure the path.")?;

        let result = script::run_cura_slice(cura_path, script)?;
        Ok(result)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将使用 CuraEngine 执行切片操作:\n{}",
                script
            )),
            vec![],
        ))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        let cura_path = self
            .cura_path
            .as_ref()
            .ok_or("CuraEngine not found")?;

        let mut cmd = Command::new(cura_path);
        cmd.arg("--version");
        let (stdout, _, _) = ai_design_core::proc::run_command(&mut cmd)
            .map_err(|e| format!("Failed to get CuraEngine version: {}", e))?;

        let version = stdout;

        Ok(SoftwareState {
            active_document: "untitled".into(),
            selected_nodes: vec![],
            layers: vec![format!("CuraEngine: {}", version.trim())],
            extra: None,
        })
    }
}
