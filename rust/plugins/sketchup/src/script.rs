use ai_design_core::ScriptResult;
use std::io::Write;
use std::process::ExitStatus;
#[cfg(any(target_os = "windows", target_os = "macos"))]
use std::process::Command;

pub fn run_sketchup_script(sketchup_path: &str, script: &str) -> Result<ScriptResult, String> {
    let mut temp = tempfile::NamedTempFile::new()
        .map_err(|e| format!("Failed to create temp file: {}", e))?;
    temp.write_all(script.as_bytes())
        .map_err(|e| format!("Failed to write script: {}", e))?;

    let base = temp.path().to_string_lossy().to_string();
    let rb_path = format!("{}.rb", base);
    std::fs::rename(&base, &rb_path)
        .map_err(|e| format!("Failed to rename: {}", e))?;

    #[cfg(target_os = "windows")]
    let result: Result<(String, String, ExitStatus), String> = {
        let mut cmd = Command::new(sketchup_path);
        cmd.arg("-RubyStartup").arg(&rb_path);
        ai_design_core::proc::run_command(&mut cmd)
    };

    #[cfg(target_os = "macos")]
    let result: Result<(String, String, ExitStatus), String> = {
        let mut cmd = Command::new("osascript");
        cmd.arg("-e")
            .arg(format!("tell application \"SketchUp\" to open \"{}\"", rb_path));
        ai_design_core::proc::run_command(&mut cmd)
    };

    #[cfg(target_os = "linux")]
    let result: Result<(String, String, ExitStatus), String> =
        Err("SketchUp not available on Linux".into());

    let _ = std::fs::remove_file(&rb_path);

    match result {
        Ok((out, _, status)) if status.success() => Ok(ScriptResult::success(Some(out), vec![])),
        Ok((_, err, _)) => Ok(ScriptResult::failure(format!(
            "SketchUp script failed: {}",
            err
        ))),
        Err(e) => Ok(ScriptResult::failure(format!(
            "SketchUp unavailable: {}. Ruby script prepared for manual paste in SketchUp Ruby Console.",
            e
        ))),
    }
}
