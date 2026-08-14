use std::io::Read;
use std::process::{Command, ExitStatus, Stdio};
use std::sync::mpsc;
use std::time::{Duration, Instant};

/// Shared hard timeout for script execution (120s), matching the Dart side.
pub const EXEC_TIMEOUT: Duration = Duration::from_secs(120);

/// Read a stream as bytes and decode: strict UTF-8 first; on failure fall
/// back to GBK (Windows console apps like Blender often emit GBK bytes).
/// Output containing NUL bytes is treated as binary and rejected instead of
/// being decoded into garbage.
pub fn read_lossy<R: Read>(mut reader: R) -> Result<String, String> {
    let mut buf = Vec::new();
    reader
        .read_to_end(&mut buf)
        .map_err(|e| format!("Failed to read process output: {e}"))?;
    // NUL is valid UTF-8, so it must be rejected before any decode attempt.
    if buf.contains(&0) {
        return Err("Process produced binary output (NUL bytes); refusing to decode".to_string());
    }
    match std::str::from_utf8(&buf) {
        Ok(s) => Ok(s.to_string()),
        Err(_) => Ok(encoding_rs::GBK.decode(&buf).0.into_owned()),
    }
}

/// Kill the child and, on Unix, its whole process group (the child is spawned
/// with `process_group(0)` so it leads a fresh group and every descendant is
/// reaped on timeout). Windows has no portable job-object here, so only the
/// direct child is killed.
#[cfg(unix)]
fn kill_process_tree(child: &mut std::process::Child) {
    let pid = child.id() as i32;
    let _ = child.kill();
    unsafe {
        libc::killpg(pid, libc::SIGKILL);
    }
}

#[cfg(not(unix))]
fn kill_process_tree(child: &mut std::process::Child) {
    let _ = child.kill();
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
    #[cfg(unix)]
    {
        use std::os::unix::process::CommandExt;
        // Lead a fresh process group so a timeout can killpg the whole tree.
        cmd.process_group(0);
    }
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
    let (tx, rx) = mpsc::channel::<(bool, Result<String, String>)>();
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
            Ok((is_stdout, res)) => {
                let text = match res {
                    Ok(t) => t,
                    Err(e) => {
                        kill_process_tree(&mut child);
                        let _ = child.wait();
                        let _ = out_handle.join();
                        let _ = err_handle.join();
                        return Err(e);
                    }
                };
                if is_stdout {
                    out = text;
                } else {
                    err = text;
                }
                received += 1;
            }
            Err(_) => {
                kill_process_tree(&mut child);
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

#[cfg(test)]
mod tests {
    use super::*;

    #[cfg(unix)]
    #[test]
    fn captures_stdout_stderr_and_exit_status() {
        let mut cmd = Command::new("sh");
        cmd.arg("-c").arg("echo hello; echo oops >&2; exit 3");
        let (out, err, status) =
            run_command_with_timeout(&mut cmd, Duration::from_secs(5)).unwrap();
        assert_eq!(out.trim(), "hello");
        assert!(err.contains("oops"));
        assert_eq!(status.code(), Some(3));
    }

    #[cfg(unix)]
    #[test]
    fn times_out_and_kills_whole_process_tree() {
        // `sleep 5 & wait` keeps a grandchild alive in the same process
        // group; without killpg the orphan would hold the pipes open and
        // block the reader threads, making this test fail.
        let mut cmd = Command::new("sh");
        cmd.arg("-c").arg("sleep 5 & wait");
        let start = Instant::now();
        let res = run_command_with_timeout(&mut cmd, Duration::from_millis(300));
        assert!(res.is_err());
        assert!(
            start.elapsed() < Duration::from_secs(3),
            "process tree was not killed promptly"
        );
    }

    #[cfg(unix)]
    #[test]
    fn rejects_binary_output_with_nul_bytes() {
        let mut cmd = Command::new("sh");
        cmd.arg("-c").arg("printf '\\000\\001\\002'");
        let res = run_command_with_timeout(&mut cmd, Duration::from_secs(5));
        let err = res.err().expect("binary output must be rejected");
        assert!(err.contains("binary"), "unexpected error: {err}");
    }
}
