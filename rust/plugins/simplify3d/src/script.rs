use ai_design_core::ScriptResult;
use std::io::Write;
use std::process::Command;

/// Parse the input as JSON command spec, generate a Simplify3D factory file, and invoke
/// Simplify3D.exe CLI.
///
/// Simplify3D uses .factory files for process configuration. The CLI is invoked as:
/// `Simplify3D.exe --slice factory_file.factory`
///
/// Expected JSON format:
/// ```json
/// {
///   "action": "slice",
///   "input": "/path/to/model.stl",
///   "output": "/path/to/output.gcode",
///   "config": {
///     "layer_height": 0.2,
///     "support_type": "normal",
///     "extrusion_temperature": 210,
///     "bed_temperature": 60
///   }
/// }
/// ```
pub fn run_simplify3d_slice(s3d_path: &str, command_json: &str) -> Result<ScriptResult, String> {
    let cmd: serde_json::Value = serde_json::from_str(command_json)
        .map_err(|e| format!("Failed to parse Simplify3D command JSON: {}", e))?;

    let action = cmd["action"].as_str().unwrap_or("slice");
    let input_path = cmd["input"].as_str();
    let output_path = cmd["output"].as_str().unwrap_or("output.gcode");
    let config_obj = &cmd["config"];

    match action {
        "slice" => {
            let input = input_path.ok_or("Simplify3D slice requires an 'input' path")?;

            // Generate a Simplify3D factory file (XML format)
            let mut factory_xml = String::from(
                r#"<?xml version="1.0" encoding="utf-8"?>
<Factory>
  <ModelPaths>"#,
            );
            factory_xml.push_str(input);
            factory_xml.push_str(
                r#"</ModelPaths>
  <Processes>"#,
            );

            // Build process settings
            factory_xml.push_str(r#"<Process name="Default" id="1">"#);

            if let Some(v) = config_obj.get("layer_height").and_then(|v| v.as_f64()) {
                factory_xml.push_str(&format!(
                    "<setting key=\"layerHeight\">{}</setting>",
                    v
                ));
            }
            if let Some(v) = config_obj.get("extrusion_temperature").and_then(|v| v.as_f64()) {
                factory_xml.push_str(&format!(
                    "<setting key=\"extrusionTemperature\">{}</setting>",
                    v
                ));
            }
            if let Some(v) = config_obj.get("bed_temperature").and_then(|v| v.as_f64()) {
                factory_xml.push_str(&format!(
                    "<setting key=\"bedTemperature\">{}</setting>",
                    v
                ));
            }
            if let Some(v) = config_obj.get("support_type").and_then(|v| v.as_str()) {
                let support_val = match v {
                    "normal" => "1",
                    "everywhere" => "2",
                    "from_platform" => "1",
                    "none" => "0",
                    _ => "1",
                };
                factory_xml.push_str(&format!(
                    "<setting key=\"supportType\">{}</setting>",
                    support_val
                ));
            }
            if let Some(v) = config_obj.get("infill_density").and_then(|v| v.as_f64()) {
                factory_xml.push_str(&format!(
                    "<setting key=\"infillDensity\">{}</setting>",
                    v
                ));
            }
            if let Some(v) = config_obj.get("perimeters").and_then(|v| v.as_u64()) {
                factory_xml.push_str(&format!(
                    "<setting key=\"outlineShells\">{}</setting>",
                    v
                ));
            }
            if let Some(v) = config_obj.get("print_speed").and_then(|v| v.as_f64()) {
                factory_xml.push_str(&format!(
                    "<setting key=\"defaultPrintSpeed\">{}</setting>",
                    v
                ));
            }

            // Pass through extra config keys
            let known_keys = [
                "layer_height",
                "extrusion_temperature",
                "bed_temperature",
                "support_type",
                "infill_density",
                "perimeters",
                "print_speed",
            ];
            if let Some(obj) = config_obj.as_object() {
                for (key, value) in obj {
                    if !known_keys.contains(&key.as_str()) {
                        let val_str = match value {
                            serde_json::Value::String(s) => s.clone(),
                            serde_json::Value::Number(n) => n.to_string(),
                            serde_json::Value::Bool(b) => b.to_string(),
                            _ => value.to_string(),
                        };
                        factory_xml.push_str(&format!(
                            "<setting key=\"{}\">{}</setting>",
                            key, val_str
                        ));
                    }
                }
            }

            factory_xml.push_str(
                r#"</Process>
  </Processes>
</Factory>"#,
            );

            // Write factory file to temp location
            let mut factory_file = tempfile::NamedTempFile::new()
                .map_err(|e| format!("Failed to create temp factory file: {}", e))?;
            let factory_path = factory_file.path().to_string_lossy().to_string();
            factory_file
                .write_all(factory_xml.as_bytes())
                .map_err(|e| format!("Failed to write factory file: {}", e))?;

            // Invoke Simplify3D with output gcode path
            let mut cli_args: Vec<String> = Vec::new();
            cli_args.push("--slice".to_string());
            cli_args.push(factory_path.clone());

            // Modern Simplify3D versions support --output
            if std::path::Path::new(output_path).parent().map_or(true, |p| p.exists()) {
                cli_args.push("--output".to_string());
                cli_args.push(output_path.to_string());
            }

            let args_refs: Vec<&str> = cli_args.iter().map(|s| s.as_str()).collect();
            let output = Command::new(s3d_path)
                .args(&args_refs)
                .output()
                .map_err(|e| format!("Failed to execute Simplify3D: {}", e))?;

            let stdout = String::from_utf8_lossy(&output.stdout).to_string();
            let stderr = String::from_utf8_lossy(&output.stderr).to_string();

            if output.status.success() {
                Ok(ScriptResult::success(
                    Some(format!(
                        "Simplify3D 切片成功\n输出: {}\n{}",
                        output_path, stdout
                    )),
                    vec![output_path.to_string()],
                ))
            } else {
                Ok(ScriptResult::failure(format!(
                    "Simplify3D 切片失败 (exit code: {:?})\n{}",
                    output.status.code(),
                    stderr
                )))
            }
        }
        "check_version" => {
            let output = Command::new(s3d_path)
                .arg("--version")
                .output()
                .map_err(|e| format!("Failed to run Simplify3D version: {}", e))?;

            let version = String::from_utf8_lossy(&output.stdout).to_string();
            Ok(ScriptResult::success(
                Some(format!("Simplify3D version:\n{}", version)),
                vec![],
            ))
        }
        other => Err(format!("Unknown Simplify3D action: {}", other)),
    }
}
