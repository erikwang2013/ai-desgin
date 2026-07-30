use ai_design_core::ScriptResult;
use std::io::Write;

#[cfg(any(target_os = "windows", target_os = "macos"))]
use std::process::Command;

pub fn run_rhino_script(rhino_path: &str, script: &str) -> Result<ScriptResult, String> {
    // Write script to a temp file
    let mut temp = tempfile::NamedTempFile::new()
        .map_err(|e| format!("Failed to create temp file: {}", e))?;
    temp.write_all(script.as_bytes())
        .map_err(|e| format!("Failed to write script: {}", e))?;
    let temp_path = temp.path().to_string_lossy().to_string();

    #[cfg(target_os = "windows")]
    {
        // On Windows, use Rhino's CLI with -runscript or Python script execution
        // Rhino 7+ supports running Python scripts via: rhino -runscript="...py"
        let output = Command::new(rhino_path)
            .args(["-runscript", &temp_path])
            .output()
            .map_err(|e| format!("Failed to execute Rhino: {}", e))?;

        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();

        if output.status.success() {
            Ok(ScriptResult::success(
                Some(format!("Rhino 脚本执行成功\n输出:\n{}", stdout)),
                vec![],
            ))
        } else {
            Ok(ScriptResult::failure(format!(
                "Rhino 脚本执行失败 (exit code: {:?})\n错误:\n{}",
                output.status.code(),
                stderr
            )))
        }
    }

    #[cfg(target_os = "macos")]
    {
        // On macOS, use osascript to tell Rhino to run a script
        // Rhino for Mac supports AppleScript automation
        let applescript = format!(
            r#"tell application "Rhino"
    activate
    run script "{}"
end tell"#,
            &temp_path
        );

        let output = Command::new("osascript")
            .arg("-e")
            .arg(&applescript)
            .output()
            .map_err(|e| format!("Failed to execute Rhino via osascript: {}", e))?;

        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();

        if output.status.success() {
            Ok(ScriptResult::success(
                Some(format!("Rhino (macOS) 脚本执行成功\n输出:\n{}", stdout)),
                vec![],
            ))
        } else {
            Ok(ScriptResult::failure(format!(
                "Rhino (macOS) 脚本执行失败 (exit code: {:?})\n错误:\n{}",
                output.status.code(),
                stderr
            )))
        }
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos")))]
    {
        // Rhino is not natively supported on Linux; fallback with a clear message
        let _ = rhino_path;
        let _ = temp_path;
        Ok(ScriptResult::failure(
            "Rhino 3D is not supported on Linux. Please use Windows or macOS.".into(),
        ))
    }
}
