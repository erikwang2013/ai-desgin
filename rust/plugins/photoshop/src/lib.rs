pub mod script;

use ai_design_core::{
    ConnectionConfig, ConnectionStatus, DesignCategory, DesignPlugin, PluginContext, PluginMeta,
    ScriptResult, SoftwareCapabilities, SoftwareState,
};

pub struct PhotoshopPlugin {
    meta: PluginMeta,
    photoshop_path: Option<String>,
    capabilities: SoftwareCapabilities,
}

impl PhotoshopPlugin {
    pub fn new() -> Self {
        Self {
            meta: PluginMeta {
                id: "com.aidesign.photoshop".into(),
                name: "Photoshop".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                script_language: "javascript".into(),
            },
            photoshop_path: None,
            capabilities: SoftwareCapabilities {
                actions: vec![
                    "创建文档".into(),
                    "打开文件".into(),
                    "保存文件".into(),
                    "添加图层".into(),
                    "调整色阶".into(),
                    "应用滤镜".into(),
                    "裁剪图像".into(),
                    "调整大小".into(),
                    "导出PNG".into(),
                    "导出JPG".into(),
                    "导出PSD".into(),
                    "添加文本".into(),
                    "创建选区".into(),
                    "填充颜色".into(),
                    "图层混合".into(),
                    "添加蒙版".into(),
                    "调整图层".into(),
                    "批处理".into(),
                ],
                file_formats: vec![
                    "psd".into(),
                    "png".into(),
                    "jpg".into(),
                    "gif".into(),
                    "tiff".into(),
                    "pdf".into(),
                    "svg".into(),
                    "webp".into(),
                ],
                constraints: None,
            },
        }
    }

    fn find_photoshop(&self) -> Option<String> {
        #[cfg(target_os = "windows")]
        let candidates = vec![
            "C:\\Program Files\\Adobe\\Adobe Photoshop 2024\\Photoshop.exe",
            "C:\\Program Files\\Adobe\\Adobe Photoshop 2025\\Photoshop.exe",
        ];
        #[cfg(target_os = "macos")]
        let candidates = vec![
            "/Applications/Adobe Photoshop 2024/Adobe Photoshop 2024.app/Contents/MacOS/Adobe Photoshop 2024",
            "/Applications/Adobe Photoshop 2025/Adobe Photoshop 2025.app/Contents/MacOS/Adobe Photoshop 2025",
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

impl DesignPlugin for PhotoshopPlugin {
    fn meta(&self) -> &PluginMeta {
        &self.meta
    }
    fn category(&self) -> DesignCategory {
        DesignCategory::Ad
    }

    fn initialize(&mut self, _ctx: &PluginContext) -> Result<(), String> {
        self.photoshop_path = self.find_photoshop();
        Ok(())
    }

    fn dispose(&mut self) {
        self.photoshop_path = None;
    }

    fn check_connection(&self) -> ConnectionStatus {
        match self.photoshop_path.as_ref() {
            Some(path) if std::path::Path::new(path).exists() => ConnectionStatus::Connected,
            _ => ConnectionStatus::Disconnected,
        }
    }

    fn connect(&mut self, _config: &ConnectionConfig) -> Result<bool, String> {
        self.photoshop_path = self.find_photoshop();
        Ok(self.photoshop_path.is_some())
    }

    fn capabilities(&self) -> &SoftwareCapabilities {
        &self.capabilities
    }

    fn execute(&self, script: &str) -> Result<ScriptResult, String> {
        let ps_path = self
            .photoshop_path
            .as_ref()
            .ok_or("Photoshop not found. Please install Photoshop or configure the path.")?;

        script::run_extendscript(ps_path, script)
    }

    fn preview(&self, script: &str) -> Result<ScriptResult, String> {
        Ok(ScriptResult::success(
            Some(format!(
                "[预览] 将在 Photoshop 中执行 ExtendScript:\n{}",
                script
            )),
            vec![],
        ))
    }

    fn get_current_state(&self) -> Result<SoftwareState, String> {
        let ps_path = self
            .photoshop_path
            .as_ref()
            .ok_or("Photoshop not found")?;

        let state_script = r#"
var doc = app.activeDocument;
var state = {
    activeDocument: doc ? doc.name : "",
    layers: [],
    selectedNodes: []
};
if (doc) {
    for (var i = 0; i < doc.layers.length; i++) {
        state.layers.push(doc.layers[i].name);
    }
    try { state.selectedNodes = [doc.activeLayer.name]; } catch(e) {}
}
JSON.stringify(state);
"#;

        script::run_extendscript(ps_path, state_script).map(|result| {
            if let Some(output) = &result.output {
                if let Ok(state) = serde_json::from_str::<serde_json::Value>(output) {
                    return SoftwareState {
                        active_document: state["activeDocument"]
                            .as_str()
                            .unwrap_or("")
                            .into(),
                        selected_nodes: state["selectedNodes"]
                            .as_array()
                            .map(|a| a.iter().filter_map(|v| v.as_str().map(String::from)).collect())
                            .unwrap_or_default(),
                        layers: state["layers"]
                            .as_array()
                            .map(|a| a.iter().filter_map(|v| v.as_str().map(String::from)).collect())
                            .unwrap_or_default(),
                        extra: None,
                    };
                }
            }
            SoftwareState {
                active_document: String::new(),
                selected_nodes: vec![],
                layers: vec![],
                extra: None,
            }
        })
        .or_else(|_| {
            Ok(SoftwareState {
                active_document: String::new(),
                selected_nodes: vec![],
                layers: vec![],
                extra: None,
            })
        })
    }
}
