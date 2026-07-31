use ai_design_core::ScriptResult;
use std::io::Write;
#[cfg(any(target_os = "windows", target_os = "macos"))]
use std::process::Command;

pub fn run_sketchup_script(_sketchup_path: &str, script: &str) -> Result<ScriptResult, String> {
    let mut temp = tempfile::NamedTempFile::new()
        .map_err(|e| format!("Failed to create temp file: {}", e))?;
    temp.write_all(script.as_bytes())
        .map_err(|e| format!("Failed to write script: {}", e))?;

    let base = temp.path().to_string_lossy().to_string();
    let rb_path = format!("{}.rb", base);
    std::fs::rename(&base, &rb_path)
        .map_err(|e| format!("Failed to rename: {}", e))?;

    #[cfg(target_os = "windows")]
    let result = Command::new(sketchup_path).arg("-RubyStartup").arg(&rb_path).output();

    #[cfg(target_os = "macos")]
    let result = Command::new("osascript")
        .arg("-e")
        .arg(format!("tell application \"SketchUp\" to open \"{}\"", rb_path))
        .output();

    #[cfg(target_os = "linux")]
    let result: Result<std::process::Output, _> =
        Err(std::io::Error::new(std::io::ErrorKind::NotFound, "SketchUp not available on Linux"));

    let _ = std::fs::remove_file(&rb_path);

    match result {
        Ok(output) if output.status.success() => Ok(ScriptResult::success(
            Some(String::from_utf8_lossy(&output.stdout).to_string()), vec![],
        )),
        Ok(output) => Ok(ScriptResult::failure(format!(
            "SketchUp script failed: {}", String::from_utf8_lossy(&output.stderr)
        ))),
        Err(e) => Ok(ScriptResult::failure(format!(
            "SketchUp unavailable: {}. Ruby script prepared for manual paste in SketchUp Ruby Console.", e
        ))),
    }
}
