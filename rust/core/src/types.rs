use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DesignCategory {
    Web,
    Ad,
    Industrial,
    ThreeD,
    Arch,
    Interior,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ConnectionStatus {
    Disconnected,
    Connecting,
    Connected,
    Error,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginMeta {
    pub id: String,
    pub name: String,
    pub version: String,
    pub script_language: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginContext {
    pub plugin_dir: String,
    pub data_dir: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConnectionConfig {
    pub host: String,
    pub port: u16,
    pub extra: Option<std::collections::HashMap<String, String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SoftwareCapabilities {
    pub actions: Vec<String>,
    pub file_formats: Vec<String>,
    pub constraints: Option<std::collections::HashMap<String, String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SoftwareState {
    pub active_document: String,
    pub selected_nodes: Vec<String>,
    pub layers: Vec<String>,
    pub extra: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScriptResult {
    pub success: bool,
    pub output: Option<String>,
    pub error: Option<String>,
    pub artifacts: Vec<String>,
    pub metadata: Option<serde_json::Value>,
}

impl ScriptResult {
    pub fn success(output: Option<String>, artifacts: Vec<String>) -> Self {
        Self { success: true, output, error: None, artifacts, metadata: None }
    }

    pub fn failure(error: String) -> Self {
        Self { success: false, output: None, error: Some(error), artifacts: vec![], metadata: None }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn script_result_success_constructor() {
        let r = ScriptResult::success(Some("ok".to_string()), vec!["a.png".to_string()]);
        assert!(r.success);
        assert_eq!(r.output.as_deref(), Some("ok"));
        assert!(r.error.is_none());
        assert_eq!(r.artifacts, vec!["a.png"]);
        assert!(r.metadata.is_none());
    }

    #[test]
    fn script_result_failure_constructor() {
        let r = ScriptResult::failure("boom".to_string());
        assert!(!r.success);
        assert!(r.output.is_none());
        assert_eq!(r.error.as_deref(), Some("boom"));
        assert!(r.artifacts.is_empty());
    }

    #[test]
    fn script_result_json_round_trip() {
        let r = ScriptResult::success(None, vec![]);
        let json = serde_json::to_string(&r).unwrap();
        let back: ScriptResult = serde_json::from_str(&json).unwrap();
        assert_eq!(back.success, r.success);
        assert_eq!(back.output, r.output);
        assert_eq!(back.error, r.error);
        assert_eq!(back.artifacts, r.artifacts);
        // 序列化后字段键名需与 Dart 侧一致
        let value: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(value["success"], true);
        assert_eq!(value["artifacts"], serde_json::Value::Array(vec![]));
    }

    #[test]
    fn plugin_meta_json_round_trip() {
        let m = PluginMeta {
            id: "figma".into(),
            name: "Figma".into(),
            version: "1.0.0".into(),
            script_language: "javascript".into(),
        };
        let json = serde_json::to_string(&m).unwrap();
        let back: PluginMeta = serde_json::from_str(&json).unwrap();
        assert_eq!(back.id, "figma");
        assert_eq!(back.version, "1.0.0");
    }

    #[test]
    fn design_category_json_names() {
        // 枚举序列化名是 Dart 侧匹配契约，改动会破坏跨语言解码。
        assert_eq!(serde_json::to_string(&DesignCategory::Web).unwrap(), "\"Web\"");
        assert_eq!(serde_json::to_string(&DesignCategory::Interior).unwrap(), "\"Interior\"");
        // 枚举无 PartialEq，以序列化一致性断言往返
        let back = serde_json::from_str::<DesignCategory>("\"ThreeD\"").unwrap();
        assert_eq!(serde_json::to_string(&back).unwrap(), "\"ThreeD\"");
    }

    #[test]
    fn connection_status_round_trip() {
        for s in [ConnectionStatus::Disconnected, ConnectionStatus::Connecting,
                  ConnectionStatus::Connected, ConnectionStatus::Error] {
            let json = serde_json::to_string(&s).unwrap();
            // 枚举无 PartialEq，以序列化一致性断言往返
            let back = serde_json::from_str::<ConnectionStatus>(&json).unwrap();
            assert_eq!(serde_json::to_string(&back).unwrap(), json);
        }
    }

    #[test]
    fn software_state_round_trip() {
        let s = SoftwareState {
            active_document: "doc.psd".into(),
            selected_nodes: vec!["n1".into()],
            layers: vec!["bg".into()],
            extra: Some(serde_json::json!({"zoom": 1.5})),
        };
        let back: SoftwareState = serde_json::from_str(&serde_json::to_string(&s).unwrap()).unwrap();
        assert_eq!(back.active_document, "doc.psd");
        assert_eq!(back.extra.unwrap()["zoom"], 1.5);
    }
}
