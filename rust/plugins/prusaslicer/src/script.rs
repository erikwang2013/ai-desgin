use ai_design_core::ScriptResult;
use std::io::Write;
use std::process::Command;

/// Parse the input as JSON command spec, write a PrusaSlicer config.ini, and invoke prusa-slicer.
///
/// Expected JSON format:
/// ```json
/// {
///   "action": "slice",
///   "input": "/path/to/model.stl",
///   "output": "/path/to/output.gcode",
///   "config": {
///     "layer_height": 0.2,
///     "fill_density": "20%",
///     "support_material": true,
///     "printer_preset": "Original Prusa i3 MK3S & MK3S+"
///   }
/// }
/// ```
pub fn run_prusa_slicer(slicer_path: &str, command_json: &str) -> Result<ScriptResult, String> {
    let cmd: serde_json::Value = serde_json::from_str(command_json)
        .map_err(|e| format!("Failed to parse PrusaSlicer command JSON: {}", e))?;

    let action = cmd["action"].as_str().unwrap_or("slice");
    let input_path = cmd["input"].as_str();
    let output_path = cmd["output"].as_str().unwrap_or("output.gcode");
    let config_obj = &cmd["config"];

    match action {
        "slice" => {
            let input = input_path.ok_or("PrusaSlicer slice requires an 'input' path")?;

            // Build a PrusaSlicer INI-style config string
            let mut ini_lines: Vec<String> = Vec::new();

            if let Some(v) = config_obj.get("layer_height").and_then(|v| v.as_f64()) {
                ini_lines.push(format!("layer_height = {}", v));
            }
            if let Some(v) = config_obj.get("fill_density").and_then(|v| v.as_str()) {
                ini_lines.push(format!("fill_density = {}", v));
            }
            if let Some(v) = config_obj.get("support_material").and_then(|v| v.as_bool()) {
                ini_lines.push(format!(
                    "support_material = {}",
                    if v { "1" } else { "0" }
                ));
            }
            if let Some(v) = config_obj.get("perimeters").and_then(|v| v.as_u64()) {
                ini_lines.push(format!("perimeters = {}", v));
            }
            if let Some(v) = config_obj.get("top_solid_layers").and_then(|v| v.as_u64()) {
                ini_lines.push(format!("top_solid_layers = {}", v));
            }
            if let Some(v) = config_obj.get("bottom_solid_layers").and_then(|v| v.as_u64()) {
                ini_lines.push(format!("bottom_solid_layers = {}", v));
            }
            if let Some(v) = config_obj.get("nozzle_temperature").and_then(|v| v.as_f64()) {
                ini_lines.push(format!("nozzle_temperature = {}", v));
            }
            if let Some(v) = config_obj.get("bed_temperature").and_then(|v| v.as_f64()) {
                ini_lines.push(format!("bed_temperature = {}", v));
            }
            if let Some(v) = config_obj.get("fill_pattern").and_then(|v| v.as_str()) {
                ini_lines.push(format!("fill_pattern = {}", v));
            }

            // Pass through extra config keys
            let known_keys = [
                "layer_height",
                "fill_density",
                "support_material",
                "perimeters",
                "top_solid_layers",
                "bottom_solid_layers",
                "nozzle_temperature",
                "bed_temperature",
                "fill_pattern",
            ];
            if let Some(obj) = config_obj.as_object() {
                for (key, value) in obj {
                    if !known_keys.contains(&key.as_str()) {
                        let val_str = match value {
                            serde_json::Value::String(s) => s.clone(),
                            serde_json::Value::Number(n) => n.to_string(),
                            serde_json::Value::Bool(b) => {
                                if *b { "1".to_string() } else { "0".to_string() }
                            }
                            _ => value.to_string(),
                        };
                        ini_lines.push(format!("{} = {}", key, val_str));
                    }
                }
            }

            let ini_content = ini_lines.join("\n");

            // Write config to temp file
            let mut config_file = tempfile::NamedTempFile::new()
                .map_err(|e| format!("Failed to create temp config file: {}", e))?;
            let config_path = config_file.path().to_string_lossy().to_string();
            config_file
                .write_all(ini_content.as_bytes())
                .map_err(|e| format!("Failed to write config file: {}", e))?;

            // Invoke prusa-slicer
            let mut cmd = Command::new(slicer_path);
            cmd.args([
                "--slice",
                "--load",
                &config_path,
                "--output",
                output_path,
                input,
            ]);
            let (stdout, stderr, status) = ai_design_core::proc::run_command(&mut cmd)
                .map_err(|e| format!("Failed to execute PrusaSlicer: {}", e))?;

            if status.success() {
                Ok(ScriptResult::success(
                    Some(format!(
                        "PrusaSlicer 切片成功\n输出: {}\n{}",
                        output_path, stdout
                    )),
                    vec![output_path.to_string()],
                ))
            } else {
                Ok(ScriptResult::failure(format!(
                    "PrusaSlicer 切片失败 (exit code: {:?})\n{}",
                    status.code(),
                    stderr
                )))
            }
        }
        "check_version" => {
            let mut cmd = Command::new(slicer_path);
            cmd.arg("--version");
            let (stdout, _, _) = ai_design_core::proc::run_command(&mut cmd)
                .map_err(|e| format!("Failed to run PrusaSlicer version: {}", e))?;

            Ok(ScriptResult::success(
                Some(format!("PrusaSlicer version:\n{}", stdout)),
                vec![],
            ))
        }
        other => Err(format!("Unknown PrusaSlicer action: {}", other)),
    }
}
