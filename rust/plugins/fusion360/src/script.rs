use ai_design_core::ScriptResult;
use std::process::ExitStatus;

/// Write a Python script to a temp file and execute it via Fusion 360's
/// built-in Python interpreter (accessible through its API).
///
/// Fusion 360 ships with a CPython interpreter that exposes the `adsk`
/// namespace (`adsk.core`, `adsk.fusion`, `adsk.cam`). This function
/// wraps the user script in a minimal bootstrap that ensures Fusion 360
/// is running and the API imports are available.
pub fn run_fusion360_script(fusion360_path: &str, script: &str) -> Result<ScriptResult, String> {
    let python_script = format!(
        r#"import sys, traceback

_BOOTSTRAP = """
import adsk.core
import adsk.fusion
import adsk.cam
import traceback
"""

_USER_SCRIPT = """
{user_script}
"""

def main():
    try:
        exec(_BOOTSTRAP)
        exec(_USER_SCRIPT)
    except Exception:
        print("ERROR_START", file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
        print("ERROR_END", file=sys.stderr)

if __name__ == "__main__":
    main()
"#,
        user_script = script
    );

    let _py_ext = tempfile::NamedTempFile::new()
        .map_err(|e| format!("Failed to create temp file: {}", e))?;
    let py_path = _py_ext.path().with_extension("py");

    // Write to a proper path that won't be deleted early
    let script_path = py_path.to_string_lossy().to_string();

    let mut file =
        std::fs::File::create(&script_path).map_err(|e| format!("Failed to create script: {}", e))?;
    std::io::Write::write_all(&mut file, python_script.as_bytes())
        .map_err(|e| format!("Failed to write script: {}", e))?;
    std::io::Write::flush(&mut file)
        .map_err(|e| format!("Failed to flush script: {}", e))?;
    drop(file);

    let (stdout, stderr, status) = run_fusion360_process(fusion360_path, &script_path)?;

    // Clean up temp file
    let _ = std::fs::remove_file(&script_path);

    let has_error = stderr.contains("ERROR_START") || !status.success();

    if has_error {
        let error_detail = if stderr.contains("ERROR_START") {
            extract_error_block(&stderr)
        } else {
            stderr.clone()
        };
        Ok(ScriptResult::failure(format!(
            "Fusion 360 脚本执行失败:\n{}",
            error_detail
        )))
    } else {
        Ok(ScriptResult::success(
            Some(format!("Fusion 360 脚本执行成功\n{}", stdout)),
            vec![],
        ))
    }
}

/// Platform-specific Fusion 360 process launching.
/// Returns the process output or an error string.
#[cfg(target_os = "macos")]
fn run_fusion360_process(
    fusion360_path: &str,
    script_path: &str,
) -> Result<(String, String, ExitStatus), String> {
    let mut cmd = std::process::Command::new("open");
    cmd.args(["-a", fusion360_path, "--args", "-p", script_path]);
    ai_design_core::proc::run_command(&mut cmd)
        .map_err(|e| format!("Failed to execute Fusion 360: {e}"))
}

#[cfg(target_os = "windows")]
fn run_fusion360_process(
    fusion360_path: &str,
    script_path: &str,
) -> Result<(String, String, ExitStatus), String> {
    let mut cmd = std::process::Command::new(fusion360_path);
    cmd.args(["-p", script_path]);
    ai_design_core::proc::run_command(&mut cmd)
        .map_err(|e| format!("Failed to execute Fusion 360: {e}"))
}

#[cfg(target_os = "linux")]
fn run_fusion360_process(
    _fusion360_path: &str,
    _script_path: &str,
) -> Result<(String, String, ExitStatus), String> {
    Err("Fusion 360 is not available on Linux".into())
}

fn extract_error_block(stderr: &str) -> String {
    let mut in_block = false;
    let mut lines = Vec::new();
    for line in stderr.lines() {
        match line.trim() {
            "ERROR_START" => in_block = true,
            "ERROR_END" => break,
            _ if in_block => lines.push(line),
            _ => {}
        }
    }
    lines.join("\n")
}
