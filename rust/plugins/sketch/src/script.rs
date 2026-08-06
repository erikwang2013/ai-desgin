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

    let mut cmd = Command::new("sketchtool");
    cmd.arg("run").arg(&js_path);
    let result = ai_design_core::proc::run_command(&mut cmd);

    let output = match result {
        Ok((out, _, status)) if status.success() => Ok((out, String::new(), status)),
        _ => {
            let mut cmd2 = Command::new("osascript");
            cmd2.arg("-e").arg(format!(
                "tell application \"Sketch\" to run script file \"{}\"",
                js_path
            ));
            ai_design_core::proc::run_command(&mut cmd2)
        }
    };

    let _ = std::fs::remove_file(&js_path);

    match output {
        Ok((out, _, status)) if status.success() => Ok(ScriptResult::success(Some(out), vec![])),
        Ok((_, err, _)) => Ok(ScriptResult::failure(format!("Sketch script failed: {}", err))),
        Err(e) => Ok(ScriptResult::failure(format!("Failed to run Sketch: {}", e))),
    }
}
