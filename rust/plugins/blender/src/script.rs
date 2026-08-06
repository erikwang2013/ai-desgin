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

    let mut cmd = Command::new(blender_path);
    cmd.args(["--background", "--python", &temp_path]);
    let (stdout, stderr, status) = ai_design_core::proc::run_command(&mut cmd)
        .map_err(|e| format!("Failed to execute Blender: {e}"))?;

    if status.success() {
        Ok(ScriptResult::success(
            Some(format!("Blender 脚本执行成功\n输出:\n{}", stdout)),
            vec![],
        ))
    } else {
        Ok(ScriptResult::failure(format!(
            "Blender 脚本执行失败 (exit code: {:?})\n错误:\n{}",
            status.code(),
            stderr
        )))
    }
}
