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
