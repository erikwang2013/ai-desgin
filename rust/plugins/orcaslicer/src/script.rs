use ai_design_core::ScriptResult;
use std::process::Command;

/// Parse the input as JSON command spec and invoke orca-slicer CLI.
///
/// OrcaSlicer shares much of its CLI with PrusaSlicer / Bambu Studio.
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
///     "printer_preset": "Bambu Lab X1 Carbon"
///   }
/// }
/// ```
pub fn run_orca_slicer(slicer_path: &str, command_json: &str) -> Result<ScriptResult, String> {
    let cmd: serde_json::Value = serde_json::from_str(command_json)
        .map_err(|e| format!("Failed to parse OrcaSlicer command JSON: {}", e))?;

    let action = cmd["action"].as_str().unwrap_or("slice");
    let input_path = cmd["input"].as_str();
    let output_path = cmd["output"].as_str().unwrap_or("output.gcode");
    let config_obj = &cmd["config"];

    match action {
        "slice" => {
            let input = input_path.ok_or("OrcaSlicer slice requires an 'input' path")?;

            // Build OrcaSlicer config as a set of CLI --key=value arguments
            // OrcaSlicer also supports config files; for simplicity we pass key=value args directly.
            let mut cli_args: Vec<String> = Vec::new();

            cli_args.push("--slice".to_string());
            cli_args.push("--output".to_string());
            cli_args.push(output_path.to_string());

            // Map known config keys to CLI arguments
            if let Some(v) = config_obj.get("layer_height").and_then(|v| v.as_f64()) {
                cli_args.push(format!("--layer-height={}", v));
            }
            if let Some(v) = config_obj.get("fill_density").and_then(|v| v.as_str()) {
                cli_args.push(format!("--fill-density={}", v));
            }
            if let Some(v) = config_obj.get("support_material").and_then(|v| v.as_bool()) {
                cli_args.push(format!(
                    "--support-material={}",
                    if v { "1" } else { "0" }
                ));
            }
            if let Some(v) = config_obj.get("nozzle_temperature").and_then(|v| v.as_f64()) {
                cli_args.push(format!("--nozzle-temperature={}", v));
            }
            if let Some(v) = config_obj.get("bed_temperature").and_then(|v| v.as_f64()) {
                cli_args.push(format!("--bed-temperature={}", v));
            }
            if let Some(v) = config_obj.get("perimeters").and_then(|v| v.as_u64()) {
                cli_args.push(format!("--perimeters={}", v));
            }
            if let Some(v) = config_obj.get("top_solid_layers").and_then(|v| v.as_u64()) {
                cli_args.push(format!("--top-solid-layers={}", v));
            }
            if let Some(v) = config_obj.get("bottom_solid_layers").and_then(|v| v.as_u64()) {
                cli_args.push(format!("--bottom-solid-layers={}", v));
            }

            // Pass through extra config keys as --key=value
            let known_keys = [
                "layer_height",
                "fill_density",
                "support_material",
                "nozzle_temperature",
                "bed_temperature",
                "perimeters",
                "top_solid_layers",
                "bottom_solid_layers",
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
                        let snake_key = key.replace('-', "_");
                        cli_args.push(format!("--{}={}", snake_key, val_str));
                    }
                }
            }

            cli_args.push(input.to_string());

            // Invoke orca-slicer
            let args_refs: Vec<&str> = cli_args.iter().map(|s| s.as_str()).collect();
            let mut cmd = Command::new(slicer_path);
            cmd.args(&args_refs);
            let (stdout, stderr, status) = ai_design_core::proc::run_command(&mut cmd)
                .map_err(|e| format!("Failed to execute OrcaSlicer: {}", e))?;

            if status.success() {
                Ok(ScriptResult::success(
                    Some(format!(
                        "OrcaSlicer 切片成功\n输出: {}\n{}",
                        output_path, stdout
                    )),
                    vec![output_path.to_string()],
                ))
            } else {
                Ok(ScriptResult::failure(format!(
                    "OrcaSlicer 切片失败 (exit code: {:?})\n{}",
                    status.code(),
                    stderr
                )))
            }
        }
        "check_version" => {
            let mut cmd = Command::new(slicer_path);
            cmd.arg("--version");
            let (stdout, _, _) = ai_design_core::proc::run_command(&mut cmd)
                .map_err(|e| format!("Failed to run OrcaSlicer version: {}", e))?;

            Ok(ScriptResult::success(
                Some(format!("OrcaSlicer version:\n{}", stdout)),
                vec![],
            ))
        }
        other => Err(format!("Unknown OrcaSlicer action: {}", other)),
    }
}
