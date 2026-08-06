use std::process::{Command, ExitStatus, Stdio};
use std::sync::mpsc;
use std::time::Duration;

/// Shared hard timeout for script execution (120s), matching the Dart side.
pub const EXEC_TIMEOUT: Duration = Duration::from_secs(120);

/// Run a command capturing stdout/stderr on reader threads with a hard
/// timeout. On timeout the child is killed so a hung process (e.g. a
/// stuck Blender/FreeCAD) cannot block the caller forever.
/// Returns (stdout, stderr, exit_status).
pub fn run_command_with_timeout(
    cmd: &mut Command,
    timeout: Duration,
) -> Result<(String, String, ExitStatus), String> {
    cmd.stdout(Stdio::piped()).stderr(Stdio::piped());
    let mut child = cmd
        .spawn()
        .map_err(|e| format!("Failed to execute command: {e}"))?;
    let stdout = child
        .stdout
        .take()
        .ok_or_else(|| "Failed to open stdout".to_string())?;
    let stderr = child
        .stderr
        .take()
        .ok_or_else(|| "Failed to open stderr".to_string())?;
    let (tx, rx) = mpsc::channel();
    let handle = std::thread::spawn(move || {
        let out = std::io::read_to_string(stdout).unwrap_or_default();
        let err = std::io::read_to_string(stderr).unwrap_or_default();
        let _ = tx.send((out, err));
    });

    let (out, err) = match rx.recv_timeout(timeout) {
        Ok(ok) => ok,
        Err(_) => {
            let _ = child.kill();
            let _ = handle.join();
            return Err("Script execution timed out, process killed".to_string());
        }
    };
    let status = child
        .wait()
        .map_err(|e| format!("Process wait error: {e}"))?;
    Ok((out, err, status))
}

/// Convenience: run with the shared 120s timeout.
pub fn run_command(cmd: &mut Command) -> Result<(String, String, ExitStatus), String> {
    run_command_with_timeout(cmd, EXEC_TIMEOUT)
}
