use ai_design_core::ScriptResult;
use std::io::Write;
use std::process::Command;

pub fn run_freecad_script(freecad_path: &str, script: &str) -> Result<ScriptResult, String> {
    // Write script to temp file for execution
    let mut temp = tempfile::NamedTempFile::new()
        .map_err(|e| format!("Failed to create temp file: {}", e))?;
    temp.write_all(script.as_bytes())
        .map_err(|e| format!("Failed to write script: {}", e))?;
    let temp_path = temp.path().to_string_lossy().to_string();

    // FreeCAD headless mode: use -c (console) or the appropriate flag.
    // FreeCADCmd is the headless variant; FreeCAD --console also works.
    let is_cmd = freecad_path.contains("FreeCADCmd") || freecad_path.contains("freecadcmd");

    let output = if is_cmd {
        // FreeCADCmd runs in headless mode directly
        Command::new(freecad_path)
            .arg("--runscript")
            .arg(&temp_path)
            .output()
            .map_err(|e| format!("Failed to execute FreeCAD: {}", e))?
    } else {
        // Use --console flag for the GUI version
        Command::new(freecad_path)
            .args(["--console", "--runscript", &temp_path])
            .output()
            .map_err(|e| format!("Failed to execute FreeCAD: {}", e))?
    };

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();

    if output.status.success() {
        Ok(ScriptResult::success(
            Some(format!("FreeCAD 脚本执行成功\n输出:\n{}", stdout)),
            vec![],
        ))
    } else {
        Ok(ScriptResult::failure(format!(
            "FreeCAD 脚本执行失败 (exit code: {:?})\n错误:\n{}",
            output.status.code(),
            stderr
        )))
    }
}
