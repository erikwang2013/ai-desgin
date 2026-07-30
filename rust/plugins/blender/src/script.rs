use ai_design_core::ScriptResult;
use std::io::Write;
use std::process::Command;

pub fn run_blender_script(blender_path: &str, script: &str) -> Result<ScriptResult, String> {
    // Write script to temp file for cleaner execution
    let mut temp = tempfile::NamedTempFile::new()
        .map_err(|e| format!("Failed to create temp file: {}", e))?;
    temp.write_all(script.as_bytes())
        .map_err(|e| format!("Failed to write script: {}", e))?;
    let temp_path = temp.path().to_string_lossy().to_string();

    let output = Command::new(blender_path)
        .args(["--background", "--python", &temp_path])
        .output()
        .map_err(|e| format!("Failed to execute Blender: {}", e))?;

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();

    if output.status.success() {
        Ok(ScriptResult::success(
            Some(format!("Blender 脚本执行成功\n输出:\n{}", stdout)),
            vec![],
        ))
    } else {
        Ok(ScriptResult::failure(format!(
            "Blender 脚本执行失败 (exit code: {:?})\n错误:\n{}",
            output.status.code(),
            stderr
        )))
    }
}
