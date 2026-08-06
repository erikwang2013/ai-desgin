use ai_design_core::ScriptResult;
use std::io::Write;
#[cfg(any(target_os = "windows", target_os = "macos"))]
use std::process::Command;

/// Execute an ExtendScript (.jsx) in Photoshop.
/// Strategy varies by platform:
/// - Windows: use `photoshop.exe script.jsx`
/// - macOS: use `osascript` to tell Photoshop to run the script
pub fn run_extendscript(photoshop_path: &str, script: &str) -> Result<ScriptResult, String> {
    // Write script to temp file
    let mut temp = tempfile::NamedTempFile::new()
        .map_err(|e| format!("Failed to create temp file: {}", e))?;
    temp.write_all(script.as_bytes())
        .map_err(|e| format!("Failed to write script: {}", e))?;

    // ExtendScript files need .jsx extension
    let base = temp.path().to_string_lossy().to_string();
    let jsx_path = format!("{}.jsx", base);
    std::fs::rename(&base, &jsx_path)
        .map_err(|e| format!("Failed to rename script file: {}", e))?;

    let result = run_impl(photoshop_path, &jsx_path);

    // Clean up temp file
    let _ = std::fs::remove_file(&jsx_path);

    result
}

#[cfg(target_os = "windows")]
fn run_impl(photoshop_path: &str, jsx_path: &str) -> Result<ScriptResult, String> {
    let mut cmd = Command::new(photoshop_path);
    cmd.args([jsx_path]);
    let (stdout, _, status) = ai_design_core::proc::run_command(&mut cmd)
        .map_err(|e| format!("Failed to execute Photoshop: {e}"))?;

    if status.success() {
        Ok(ScriptResult::success(
            Some(format!("Photoshop 脚本执行成功\n{}", stdout)),
            vec![],
        ))
    } else {
        Ok(ScriptResult::failure(format!(
            "Photoshop 脚本执行失败\nstdout: {}",
            stdout
        )))
    }
}

#[cfg(target_os = "macos")]
fn run_impl(photoshop_path: &str, jsx_path: &str) -> Result<ScriptResult, String> {
    // Try multiple Photoshop version names for osascript
    let versions = ["Adobe Photoshop 2025", "Adobe Photoshop 2024", "Adobe Photoshop"];
    let mut last_err = String::new();

    for app_name in &versions {
        let escaped_path = jsx_path.replace('"', "\\\"");
        let applescript = format!(
            r#"tell application "{}" to do javascript file "{}""#,
            app_name, escaped_path
        );

        let mut cmd = Command::new("osascript");
        cmd.args(["-e", &applescript]);
        let (stdout, stderr, status) = match ai_design_core::proc::run_command(&mut cmd) {
            Ok(ok) => ok,
            Err(e) => {
                last_err = format!("osascript error: {e}");
                continue;
            }
        };

        if status.success() {
            return Ok(ScriptResult::success(
                Some(format!("Photoshop 脚本执行成功\n{}", stdout)),
                vec![],
            ));
        }

        // If osascript ran successfully but status is not 0, the app was found
        // but the script may have errored — return the actual error
        return Ok(ScriptResult::failure(format!(
            "Photoshop 脚本执行失败\n{}",
            stderr
        )));
    }

    Err(format!(
        "Photoshop not found. Tried: {}. Last error: {}",
        versions.join(", "),
        last_err
    ))
}

#[cfg(target_os = "linux")]
fn run_impl(_photoshop_path: &str, jsx_path: &str) -> Result<ScriptResult, String> {
    let _ = jsx_path;
    Err("Photoshop is not available on Linux".into())
}
