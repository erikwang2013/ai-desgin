pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct OpenSCADPlugin {
    meta: PluginMeta,
    openscad_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl Default for OpenSCADPlugin {
    fn default() -> Self {
        Self::new()
    }
}

impl OpenSCADPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.openscad".into(),
                name: "OpenSCAD".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "openscad".into(),
            },
            openscad_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建立方体".into(),
                    "创建球体".into(),
                    "布尔差集".into(),
                    "布尔交集".into(),
                    "线性挤出".into(),
                    "旋转挤出".into(),
                    "导入STL".into(),
                    "导出STL".into(),
                    "导出SCAD".into(),
                ],
                file_formats: vec![
                    "scad".into(),
                    "stl".into(),
                    "off".into(),
                    "amf".into(),
                    "3mf".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_openscad(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\OpenSCAD\\openscad.exe",
            "C:\\Program Files (x86)\\OpenSCAD\\openscad.exe",
            "openscad.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD",
            "/Applications/OpenSCAD.app/Contents/MacOS/openscad",
            "/usr/local/bin/openscad",
            "openscad",
        ];
        #[cfg(target_os = "linux")]
        let candidates = vec![
            "openscad",
            "/usr/bin/openscad",
            "/snap/bin/openscad",
            "/var/lib/flatpak/exports/bin/org.openscad.OpenSCAD",
        ];

        for path in &candidates {
            if std::path::Path::new(path).exists() {
                return Some(path.to_string());
            }
        }
        None
    }
}

impl DesignPlugin for OpenSCADPlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }

    fn category(&self) -> DesignCategory {
        DesignCategory::Industrial
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.openscad_path = self.find_openscad();
        Ok(())
    }

    fn dispose(&mut self) {
        self.openscad_path = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        match self.openscad_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.openscad_path = self.find_openscad();
        Ok(self.openscad_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let openscad_path = self
            .openscad_path
            .as_ref()
            .ok_or("OpenSCAD not found. Please install OpenSCAD or configure the path.")?;

        let result = script::run_openscad_script(openscad_path, script)?;
        Ok(result)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将在 OpenSCAD 中执行脚本:\n{}",
                script
            )),
            vec![],
        ))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        Ok(SoftwareState {
            active_document: "untitled.scad".into(),
            selected_nodes: vec![],
            layers: vec![],
            extra: None,
        })
    }
}
