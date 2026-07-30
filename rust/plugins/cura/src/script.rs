use ai_design_core::ScriptResult;
use std::io::Write;
use std::process::Command;

use serde::Serialize;

#[derive(Serialize)]
struct CuraConfig {
    /// Layer height in mm
    #[serde(rename = "layer_height")]
    pub layer_height: Option<f64>,

    /// Infill density in percent (0-100)
    #[serde(rename = "infill_sparse_density")]
    pub infill_density: Option<f64>,

    /// Whether to generate support structures
    #[serde(rename = "support_enable")]
    pub support_enabled: Option<bool>,

    /// Print speed in mm/s
    #[serde(rename = "speed_print")]
    pub print_speed: Option<f64>,

    /// Nozzle temperature in C
    #[serde(rename = "material_print_temperature")]
    pub nozzle_temperature: Option<f64>,

    /// Build plate temperature in C
    #[serde(rename = "material_bed_temperature")]
    pub bed_temperature: Option<f64>,

    /// Filament diameter in mm
    #[serde(rename = "material_diameter")]
    pub filament_diameter: Option<f64>,

    /// Wall line count
    #[serde(rename = "wall_line_count")]
    pub wall_count: Option<u32>,

    /// Top layers
    #[serde(rename = "top_layers")]
    pub top_layers: Option<u32>,

    /// Bottom layers
    #[serde(rename = "bottom_layers")]
    pub bottom_layers: Option<u32>,

    /// Nozzle diameter in mm
    #[serde(rename = "machine_nozzle_size")]
    pub nozzle_size: Option<f64>,

    /// Adhesion type (skirt, brim, raft, none)
    #[serde(rename = "adhesion_type")]
    pub adhesion_type: Option<String>,

    /// Enable retraction
    #[serde(rename = "retraction_enable")]
    pub retraction_enabled: Option<bool>,

    /// Extra settings forwarded verbatim
    #[serde(flatten)]
    pub extra: std::collections::HashMap<String, serde_json::Value>,
}

impl CuraConfig {
    pub fn new() -> Self {
        Self {
            layer_height: None,
            infill_density: None,
            support_enabled: None,
            print_speed: None,
            nozzle_temperature: None,
            bed_temperature: None,
            filament_diameter: None,
            wall_count: None,
            top_layers: None,
            bottom_layers: None,
            nozzle_size: None,
            adhesion_type: None,
            retraction_enabled: None,
            extra: std::collections::HashMap::new(),
        }
    }
}

/// Parse the input as JSON command spec, write a Cura definition file, and invoke CuraEngine.
///
/// Expected JSON format:
/// ```json
/// {
///   "action": "slice",
///   "input": "/path/to/model.stl",
///   "output": "/path/to/output.gcode",
///   "config": {
///     "layer_height": 0.2,
///     "infill_density": 20,
///     "support_enabled": true
///   }
/// }
/// ```
pub fn run_cura_slice(cura_path: &str, command_json: &str) -> Result<ScriptResult, String> {
    let cmd: serde_json::Value = serde_json::from_str(command_json)
        .map_err(|e| format!("Failed to parse Cura command JSON: {}", e))?;

    let action = cmd["action"].as_str().unwrap_or("slice");
    let input_path = cmd["input"].as_str();
    let output_path = cmd["output"].as_str().unwrap_or("output.gcode");
    let config_obj = &cmd["config"];

    match action {
        "slice" => {
            let input = input_path.ok_or("Cura slice requires an 'input' path")?;

            // Build Cura config
            let mut cfg = CuraConfig::new();
            if let Some(v) = config_obj.get("layer_height").and_then(|v| v.as_f64()) {
                cfg.layer_height = Some(v);
            }
            if let Some(v) = config_obj.get("infill_density").and_then(|v| v.as_f64()) {
                cfg.infill_density = Some(v);
            }
            if let Some(v) = config_obj.get("support_enabled").and_then(|v| v.as_bool()) {
                cfg.support_enabled = Some(v);
            }
            if let Some(v) = config_obj.get("print_speed").and_then(|v| v.as_f64()) {
                cfg.print_speed = Some(v);
            }
            if let Some(v) = config_obj.get("nozzle_temperature").and_then(|v| v.as_f64()) {
                cfg.nozzle_temperature = Some(v);
            }
            if let Some(v) = config_obj.get("bed_temperature").and_then(|v| v.as_f64()) {
                cfg.bed_temperature = Some(v);
            }
            if let Some(v) = config_obj.get("wall_count").and_then(|v| v.as_u64()) {
                cfg.wall_count = Some(v as u32);
            }
            if let Some(v) = config_obj.get("adhesion_type").and_then(|v| v.as_str()) {
                cfg.adhesion_type = Some(v.to_string());
            }

            // Pass through any extra config keys
            if let Some(obj) = config_obj.as_object() {
                let known_keys = [
                    "layer_height",
                    "infill_density",
                    "support_enabled",
                    "print_speed",
                    "nozzle_temperature",
                    "bed_temperature",
                    "wall_count",
                    "adhesion_type",
                ];
                for (key, value) in obj {
                    if !known_keys.contains(&key.as_str()) {
                        cfg.extra.insert(key.clone(), value.clone());
                    }
                }
            }

            // Write config to temp file
            let mut config_file = tempfile::NamedTempFile::new()
                .map_err(|e| format!("Failed to create temp config file: {}", e))?;
            let config_path = config_file.path().to_string_lossy().to_string();

            let config_json = serde_json::to_string_pretty(&cfg)
                .map_err(|e| format!("Failed to serialize Cura config: {}", e))?;
            config_file
                .write_all(config_json.as_bytes())
                .map_err(|e| format!("Failed to write config file: {}", e))?;

            // Invoke CuraEngine
            let output = Command::new(cura_path)
                .args([
                    "slice",
                    "-v",
                    "-j",
                    &config_path,
                    "-o",
                    output_path,
                    input,
                ])
                .output()
                .map_err(|e| format!("Failed to execute CuraEngine: {}", e))?;

            let stdout = String::from_utf8_lossy(&output.stdout).to_string();
            let stderr = String::from_utf8_lossy(&output.stderr).to_string();

            if output.status.success() {
                Ok(ScriptResult::success(
                    Some(format!(
                        "CuraEngine 切片成功\n输出: {}\n{}",
                        output_path, stdout
                    )),
                    vec![output_path.to_string()],
                ))
            } else {
                Ok(ScriptResult::failure(format!(
                    "CuraEngine 切片失败 (exit code: {:?})\n{}",
                    output.status.code(),
                    stderr
                )))
            }
        }
        "check_version" => {
            let output = Command::new(cura_path)
                .arg("--version")
                .output()
                .map_err(|e| format!("Failed to run CuraEngine version: {}", e))?;

            let version = String::from_utf8_lossy(&output.stdout).to_string();
            Ok(ScriptResult::success(
                Some(format!("CuraEngine version:\n{}", version)),
                vec![],
            ))
        }
        other => Err(format!("Unknown Cura action: {}", other)),
    }
}
