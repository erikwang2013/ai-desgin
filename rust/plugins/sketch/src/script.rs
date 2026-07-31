use ai_design_core::ScriptResult;
use std::io::Write;
use std::process::Command;

pub fn run_sketch_script(_sketch_path: &str, script: &str) -> Result<ScriptResult, String> {
    let mut temp = tempfile::NamedTempFile::new()
        .map_err(|e| format!("Failed to create temp file: {}", e))?;
    temp.write_all(script.as_bytes())
        .map_err(|e| format!("Failed to write script: {}", e))?;

    let base = temp.path().to_string_lossy().to_string();
    let js_path = format!("{}.js", base);
    std::fs::rename(&base, &js_path)
        .map_err(|e| format!("Failed to rename: {}", e))?;

    let result = Command::new("sketchtool").arg("run").arg(&js_path).output();

    let output = match result {
        Ok(ref out) if out.status.success() => result,
        _ => Command::new("osascript")
            .arg("-e")
            .arg(format!("tell application \"Sketch\" to run script file \"{}\"", js_path))
            .output(),
    };

    let _ = std::fs::remove_file(&js_path);

    match output {
        Ok(out) if out.status.success() => Ok(ScriptResult::success(
            Some(String::from_utf8_lossy(&out.stdout).to_string()), vec![],
        )),
        Ok(out) => Ok(ScriptResult::failure(format!(
            "Sketch script failed: {}", String::from_utf8_lossy(&out.stderr)
        ))),
        Err(e) => Ok(ScriptResult::failure(format!("Failed to run Sketch: {}", e))),
    }
}
