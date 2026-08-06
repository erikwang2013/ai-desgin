use ai_design_core::ScriptResult;
use std::io::Write;
use std::process::Command;

pub fn run_revit_script(_revit_path: &str, script: &str) -> Result<ScriptResult, String> {
    let mut temp = tempfile::NamedTempFile::new()
        .map_err(|e| format!("Failed to create temp file: {}", e))?;
    temp.write_all(script.as_bytes())
        .map_err(|e| format!("Failed to write script: {}", e))?;

    let base = temp.path().to_string_lossy().to_string();
    let py_path = format!("{}.py", base);
    std::fs::rename(&base, &py_path)
        .map_err(|e| format!("Failed to rename: {}", e))?;

    let mut cmd = Command::new("dynamo-cli");
    cmd.arg("run").arg(&py_path);
    let result = ai_design_core::proc::run_command(&mut cmd);

    let _ = std::fs::remove_file(&py_path);

    match result {
        Ok((out, _, status)) if status.success() => Ok(ScriptResult::success(Some(out), vec![])),
        Ok((_, err, _)) => {
            if err.contains("not found") {
                Ok(ScriptResult::failure(
                    "dynamo-cli not found. Revit script prepared for manual execution via Dynamo Player.".into(),
                ))
            } else {
                Ok(ScriptResult::failure(format!("Revit failed: {}", err)))
            }
        }
        Err(e) => Ok(ScriptResult::failure(format!(
            "dynamo-cli unavailable: {}. Use Dynamo Player in Revit to execute the script.", e
        ))),
    }
}
