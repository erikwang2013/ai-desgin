pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};
use std::process::Command;

pub struct Simplify3DPlugin {
    meta: PluginMeta,
    s3d_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for Simplify3DPlugin {
    fn default() -> Self {
        Self::new()
    }
}

impl Simplify3DPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.simplify3d".into(),
                name: "Simplify3D".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "cli".into(),
            },
            s3d_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "导入模型".into(),
                    "设置层高".into(),
                    "设置支撑".into(),
                    "切片".into(),
                    "导出GCode".into(),
                    "设置挤出温度".into(),
                ],
                file_formats: vec![
                    "stl".into(),
                    "obj".into(),
                    "3mf".into(),
                    "gcode".into(),
                    "factory".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_simplify3d(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\Simplify3D\\Simplify3D.exe",
            "C:\\Program Files\\Simplify3D 4.0\\Simplify3D.exe",
            "C:\\Program Files\\Simplify3D 4.1\\Simplify3D.exe",
            "C:\\Program Files\\Simplify3D 5.0\\Simplify3D.exe",
            "Simplify3D.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/Simplify3D.app/Contents/MacOS/Simplify3D",
            "Simplify3D",
        ];
        #[cfg(target_os = "linux")]
        let candidates = vec![
            "Simplify3D",
            "/usr/local/bin/Simplify3D",
        ];

        for path in &candidates {
            if std::path::Path::new(path).exists() {
                return Some(path.to_string());
            }
        }
        None
    }
}

impl DesignPlugin for Simplify3DPlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }
    fn category(&self) -> DesignCategory {
        DesignCategory::Industrial
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.s3d_path = self.find_simplify3d();
        Ok(())
    }

    fn dispose(&mut self) {
        self.s3d_path = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        match self.s3d_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.s3d_path = self.find_simplify3d();
        Ok(self.s3d_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let s3d_path = self
            .s3d_path
            .as_ref()
            .ok_or("Simplify3D not found. Please install Simplify3D or configure the path.")?;

        let result = script::run_simplify3d_slice(s3d_path, script)?;
        Ok(result)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将使用 Simplify3D 执行切片操作:\n{}",
                script
            )),
            vec![],
        ))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        let s3d_path = self
            .s3d_path
            .as_ref()
            .ok_or("Simplify3D not found")?;

        let output = Command::new(s3d_path)
            .arg("--help")
            .output()
            .map_err(|e| format!("Failed to check Simplify3D: {}", e))?;

        let out = String::from_utf8_lossy(&output.stdout).to_string();
        let err = String::from_utf8_lossy(&output.stderr).to_string();
        let combined = if out.is_empty() { err } else { out };

        Ok(SoftwareState {
            active_document: "untitled".into(),
            selected_nodes: vec![],
            layers: vec![format!("Simplify3D: {}", combined.trim())],
            extra: None,
        })
    }
}
