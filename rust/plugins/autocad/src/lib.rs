pub mod script;

use ai_design_core::{ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta, ScriptResult, SoftwareCapabilities, SoftwareState};
use std::process::Command;

pub struct AutoCADPlugin {
    meta: PluginMeta,
    autocad_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for AutoCADPlugin {
    fn default() -> Self {
        Self::new()
    }
}

impl AutoCADPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.autocad".into(),
                name: "AutoCAD".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "lisp".into(),
            },
            autocad_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "绘制直线".into(), "绘制圆".into(), "绘制矩形".into(),
                    "创建图层".into(), "设置尺寸标注".into(), "插入块".into(),
                    "创建多段线".into(), "填充图案".into(), "导出DWG".into(),
                    "导出DXF".into(), "导出PDF".into(), "三维拉伸".into(),
                    "创建视口".into(), "设置单位".into(),
                ],
                file_formats: vec![
                    "dwg".into(), "dxf".into(), "pdf".into(), "dwf".into(), "stl".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_autocad(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\Autodesk\\AutoCAD 2024\\acad.exe",
            "C:\\Program Files\\Autodesk\\AutoCAD 2025\\acad.exe",
            "acad.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/Autodesk/AutoCAD 2024/AutoCAD 2024.app/Contents/MacOS/AutoCAD",
            "/Applications/Autodesk/AutoCAD 2025/AutoCAD 2025.app/Contents/MacOS/AutoCAD",
        ];
        #[cfg(target_os = "linux")]
        let candidates: Vec<&str> = vec![]; // AutoCAD not available on Linux

        for path in &candidates {
            if std::path::Path::new(path).exists() {
                return Some(path.to_string());
            }
        }
        None
    }
}

impl DesignPlugin for AutoCADPlugin {
    fn meta(&self) -> &PluginMeta { &self.meta }
    fn category(&self) -> DesignCategory { DesignCategory::Arch }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.autocad_path = self.find_autocad();
        Ok(())
    }

    fn dispose(&mut self) { self.autocad_path = None; }

    fn check_connection(&self) -> ConnectionStatus {
        match self.autocad_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            Some(_) => ConnectionStatus::Disconnected,
            None => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.autocad_path = self.find_autocad();
        Ok(self.autocad_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities { &self.capabilities }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let autocad_path = self.autocad_path.as_ref()
            .ok_or("AutoCAD not found. Please install AutoCAD or configure the path.")?;

        script::run_autocad_script(autocad_path, script)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!("[预览] 将在 AutoCAD 中执行 AutoLISP 脚本:\n{}", script)),
            vec![],
        ))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        let autocad_path = self.autocad_path.as_ref()
            .ok_or("AutoCAD not found")?;

        // Query current drawing via AutoLISP
        let lisp_cmd = r#"(progn
  (setq state (strcat "{\"active_document\":\"" (getvar "DWGNAME") "\""
    ",\"selected_nodes\":[" (itoa (sslength (ssget "_I"))) "]"
    ",\"layers\":[" (getvar "CLAYER") "]}"))
  (princ state)
)"#;

        let script = script::format_autolisp_script(lisp_cmd);
        let mut cmd = Command::new(autocad_path);
        cmd.args(["/b", &script]);
        let (stdout, _, _) = ai_design_core::proc::run_command(&mut cmd)
            .map_err(|e| format!("Failed to query AutoCAD: {}", e))?;

        for line in stdout.lines() {
            if line.trim().starts_with('{') {
                if let Ok(state) = serde_json::from_str::<serde_json::Value>(line.trim()) {
                    return Ok(SoftwareState {
                        active_document: state["active_document"].as_str().unwrap_or("").into(),
                        selected_nodes: vec![],
                        layers: state["layers"].as_array()
                            .map(|a| a.iter().filter_map(|v| v.as_str().map(String::from)).collect())
                            .unwrap_or_default(),
                        extra: None,
                    });
                }
            }
        }

        Ok(SoftwareState {
            active_document: String::new(),
            selected_nodes: vec![],
            layers: vec![],
            extra: None,
        })
    }
}
