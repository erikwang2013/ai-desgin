use ai_design_core::{proc::read_lossy, ScriptResult};
use std::io::Write;
use std::process::{Child, Command, ExitStatus, Stdio};
use std::sync::mpsc;
use std::time::{Duration, Instant};

const EXEC_TIMEOUT: Duration = Duration::from_secs(120);

/// Kill the child and, on Unix, its whole process group (spawned via
/// `process_group(0)`, see `run_freecad_script`). Windows kills the direct
/// child only.
#[cfg(unix)]
fn kill_tree(child: &mut Child) {
    let _ = child.kill();
    unsafe {
        libc::killpg(child.id() as i32, libc::SIGKILL);
    }
}

#[cfg(not(unix))]
fn kill_tree(child: &mut Child) {
    let _ = child.kill();
}

/// Collect a child's stdout/stderr on separate reader threads and wait with a
/// timeout. The two streams are drained concurrently: sequential reads would
/// deadlock when the child fills one pipe (e.g. 64KB stderr) while its stdout
/// pipe stays open, stalling the whole script until a 120s false timeout.
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
    let (tx, rx) = mpsc::channel::<(bool, Result<String, String>)>();
    let out_handle = {
        let tx = tx.clone();
        std::thread::spawn(move || {
            let _ = tx.send((true, read_lossy(stdout)));
        })
    };
    let err_handle = {
        let tx = tx.clone();
        std::thread::spawn(move || {
            let _ = tx.send((false, read_lossy(stderr)));
        })
    };
    drop(tx);

    let deadline = Instant::now() + EXEC_TIMEOUT;
    let mut stdout_text = String::new();
    let mut stderr_text = String::new();
    let mut received = 0;
    while received < 2 {
        match rx.recv_timeout(deadline.saturating_duration_since(Instant::now())) {
            Ok((is_stdout, res)) => {
                let text = match res {
                    Ok(t) => t,
                    Err(e) => {
                        kill_tree(&mut child);
                        let _ = out_handle.join();
                        let _ = err_handle.join();
                        return Err(ScriptResult::failure(e));
                    }
                };
                if is_stdout {
                    stdout_text = text;
                } else {
                    stderr_text = text;
                }
                received += 1;
            }
            Err(_) => {
                kill_tree(&mut child);
                let _ = out_handle.join();
                let _ = err_handle.join();
                return Err(ScriptResult::failure(
                    "FreeCAD 脚本执行超时（120s），已终止进程".into(),
                ));
            }
        }
    }
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
    #[cfg(unix)]
    {
        use std::os::unix::process::CommandExt;
        // Lead a fresh process group so a timeout can killpg the whole tree.
        cmd.process_group(0);
    }
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
