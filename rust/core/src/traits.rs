use crate::types::*;

pub trait DesignPlugin: Send + Sync {
    fn meta(&self) -> &PluginMeta;
    fn category(&self) -> DesignCategory;

    fn initialize(&mut self, ctx: &PluginContext) -> Result<(), String>;
    fn dispose(&mut self);

    fn check_connection(&self) -> ConnectionStatus;
    fn connect(&mut self, config: &ConnectionConfig) -> Result<bool, String>;

    fn capabilities(&self) -> &SoftwareCapabilities;

    fn execute(&self, script: &str) -> Result<ScriptResult, String>;
    fn preview(&self, script: &str) -> Result<ScriptResult, String>;

    fn get_current_state(&self) -> Result<SoftwareState, String>;
}
