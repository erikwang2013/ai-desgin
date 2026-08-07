use ai_design_core::{proc::read_lossy, ScriptResult};
use std::io::Write;
use std::process::{Child, Command, ExitStatus, Stdio};
use std::sync::mpsc;
use std::time::Duration;

const EXEC_TIMEOUT: Duration = Duration::from_secs(120);

/// Collect a child's stdout/stderr on a reader thread and wait with a timeout.
/// On timeout the child is killed so a hung FreeCAD cannot block forever.
fn wait_with_timeout(mut child: Child) -> Result<(String, String, ExitStatus), ScriptResult> {
    let stdout = child
        .stdout
        .take()
        .ok_or_else(|| ScriptResult::failure("Failed to open FreeCAD stdout".into()))?;
    let stderr = child
        .stderr
        .take()
        .ok_or_else(|| ScriptResult::failure("Failed to open FreeCAD stderr".into()))?;
    let (tx, rx) = mpsc::channel();
    let handle = std::thread::spawn(move || {
        let out = read_lossy(stdout);
        let err = read_lossy(stderr);
        let _ = tx.send((out, err));
    });

    let (stdout_text, stderr_text) = match rx.recv_timeout(EXEC_TIMEOUT) {
        Ok(ok) => ok,
        Err(_) => {
            let _ = child.kill();
            let _ = handle.join();
            return Err(ScriptResult::failure(
                "FreeCAD 脚本执行超时（120s），已终止进程".into(),
            ));
        }
    };
    let status = child
        .wait()
        .map_err(|e| ScriptResult::failure(format!("FreeCAD wait error: {e}")))?;
    Ok((stdout_text, stderr_text, status))
}

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

    let mut cmd = Command::new(freecad_path);
    if is_cmd {
        // FreeCADCmd runs in headless mode directly
        cmd.arg("--runscript").arg(&temp_path);
    } else {
        // Use --console flag for the GUI version
        cmd.args(["--console", "--runscript", &temp_path]);
    }
    cmd.stdout(Stdio::piped()).stderr(Stdio::piped());
    let child = cmd
        .spawn()
        .map_err(|e| format!("Failed to execute FreeCAD: {}", e))?;

    let (stdout, stderr, status) = wait_with_timeout(child)
        .map_err(|e| e.error.unwrap_or_else(|| "FreeCAD 执行失败".into()))?;

    if status.success() {
        Ok(ScriptResult::success(
            Some(format!("FreeCAD 脚本执行成功\n输出:\n{}", stdout)),
            vec![],
        ))
    } else {
        Ok(ScriptResult::failure(format!(
            "FreeCAD 脚本执行失败 (exit code: {:?})\n错误:\n{}",
            status.code(),
            stderr
        )))
    }
}
