pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};
use std::process::Command;

pub struct PrusaSlicerPlugin {
    meta: PluginMeta,
    slicer_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for PrusaSlicerPlugin {
    fn default() -> Self {
        Self::new()
    }
}

impl PrusaSlicerPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.prusaslicer".into(),
                name: "PrusaSlicer".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "cli".into(),
            },
            slicer_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "导入STL".into(),
                    "设置层高".into(),
                    "设置填充".into(),
                    "设置支撑".into(),
                    "切片".into(),
                    "导出GCode".into(),
                    "设置打印机预设".into(),
                ],
                file_formats: vec![
                    "stl".into(),
                    "obj".into(),
                    "3mf".into(),
                    "amf".into(),
                    "gcode".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_slicer(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\Prusa3D\\PrusaSlicer\\prusa-slicer.exe",
            "C:\\Program Files\\PrusaSlicer\\prusa-slicer.exe",
            "prusa-slicer.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/PrusaSlicer.app/Contents/MacOS/prusa-slicer",
            "prusa-slicer",
        ];
        #[cfg(target_os = "linux")]
        let candidates = vec![
            "prusa-slicer",
            "/usr/bin/prusa-slicer",
            "/usr/local/bin/prusa-slicer",
            "/snap/bin/prusa-slicer",
        ];

        for path in &candidates {
            if std::path::Path::new(path).exists() {
                return Some(path.to_string());
            }
        }
        None
    }
}

impl DesignPlugin for PrusaSlicerPlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }
    fn category(&self) -> DesignCategory {
        DesignCategory::Industrial
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.slicer_path = self.find_slicer();
        Ok(())
    }

    fn dispose(&mut self) {
        self.slicer_path = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        match self.slicer_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.slicer_path = self.find_slicer();
        Ok(self.slicer_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let slicer_path = self
            .slicer_path
            .as_ref()
            .ok_or("PrusaSlicer not found. Please install PrusaSlicer or configure the path.")?;

        let result = script::run_prusa_slicer(slicer_path, script)?;
        Ok(result)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将使用 PrusaSlicer 执行切片操作:\n{}",
                script
            )),
            vec![],
        ))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        let slicer_path = self
            .slicer_path
            .as_ref()
            .ok_or("PrusaSlicer not found")?;

        let mut cmd = Command::new(slicer_path);
        cmd.arg("--info");
        let (stdout, stderr, _) = ai_design_core::proc::run_command(&mut cmd)
            .map_err(|e| format!("Failed to get PrusaSlicer info: {}", e))?;

        let combined = if stdout.trim().is_empty() { stderr } else { stdout };

        Ok(SoftwareState {
            active_document: "untitled".into(),
            selected_nodes: vec![],
            layers: vec![format!("PrusaSlicer: {}", combined.trim())],
            extra: None,
        })
    }
}
