use std::io::Read;
use std::process::{Command, ExitStatus, Stdio};
use std::sync::mpsc;
use std::time::{Duration, Instant};

/// Shared hard timeout for script execution (120s), matching the Dart side.
pub const EXEC_TIMEOUT: Duration = Duration::from_secs(120);

/// Read a stream as bytes and decode leniently: bytes that are not valid
/// UTF-8 (e.g. GBK output from Windows console apps) are replaced with
/// U+FFFD instead of failing the whole read.
pub fn read_lossy<R: Read>(mut reader: R) -> String {
    let mut buf = Vec::new();
    let _ = reader.read_to_end(&mut buf);
    String::from_utf8_lossy(&buf).into_owned()
}

/// Run a command capturing stdout/stderr on separate reader threads with a
/// hard timeout. The streams are drained concurrently so a full 64KB pipe on
/// either side cannot deadlock the child. On timeout the child is killed and
/// reaped so a hung process (e.g. a stuck Blender/FreeCAD) cannot block the
/// caller forever or leak a zombie.
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
    let (tx, rx) = mpsc::channel::<(bool, String)>();
    let out_handle = {
        let tx = tx.clone();
        std::thread::spawn(move || {
            let out = read_lossy(stdout);
            let _ = tx.send((true, out));
        })
    };
    let err_handle = {
        let tx = tx.clone();
        std::thread::spawn(move || {
            let err = read_lossy(stderr);
            let _ = tx.send((false, err));
        })
    };
    drop(tx);

    let deadline = Instant::now() + timeout;
    let mut out = String::new();
    let mut err = String::new();
    let mut received = 0;
    while received < 2 {
        match rx.recv_timeout(deadline.saturating_duration_since(Instant::now())) {
            Ok((is_stdout, text)) => {
                if is_stdout {
                    out = text;
                } else {
                    err = text;
                }
                received += 1;
            }
            Err(_) => {
                let _ = child.kill();
                let _ = child.wait();
                let _ = out_handle.join();
                let _ = err_handle.join();
                return Err("Script execution timed out, process killed".to_string());
            }
        }
    }
    let status = child
        .wait()
        .map_err(|e| format!("Process wait error: {e}"))?;
    Ok((out, err, status))
}

/// Convenience: run with the shared 120s timeout.
pub fn run_command(cmd: &mut Command) -> Result<(String, String, ExitStatus), String> {
    run_command_with_timeout(cmd, EXEC_TIMEOUT)
}
